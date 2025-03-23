;; ========================================
;; Nebula Token Contract
;; A feature-rich fungible token with enhanced security
;; ========================================

;; ========================================
;; Constants and Definitions
;; ========================================

;; Define token
(define-fungible-token nebula)

;; Token constants
(define-constant TOKEN-MAX-SUPPLY u1000000000000000) ;; 1 trillion tokens
(define-constant TOKEN-PRECISION u1000000) ;; 6 decimal places

;; Error codes - Using a semantic naming convention with numeric codes
(define-constant ACCESS-DENIED (err u9001))
(define-constant BALANCE-TOO-LOW (err u9002))
(define-constant INVALID-PARAMETER (err u9003))
(define-constant RECIPIENT-ERROR (err u9004))
(define-constant SPENDER-ERROR (err u9005))
(define-constant ARITHMETIC-ERROR (err u9006))
(define-constant CONTRACT-FROZEN (err u9007))
(define-constant ALREADY-SETUP (err u9008))
(define-constant NOT-SETUP (err u9009))
(define-constant USER-BLOCKED (err u9010))
(define-constant SUPPLY-LIMIT-REACHED (err u9011))
(define-constant ZERO-PRINCIPAL (err u9012))
(define-constant SELF-TRANSFER-ERROR (err u9013))
(define-constant APPROVAL-EXPIRED (err u9014))

;; ========================================
;; Data Storage
;; ========================================

;; Core token data
(define-data-var contract-admin principal tx-sender)
(define-data-var token-name (string-ascii 32) "Nebula Token")
(define-data-var token-symbol (string-ascii 10) "NBLA")
(define-data-var token-decimals uint u6)
(define-data-var total-supply uint u0)
(define-data-var is-frozen bool false)
(define-data-var is-setup bool false)
(define-data-var last-event-sequence uint u0)

;; Data maps for token operations
(define-map approvals 
    { owner: principal, spender: principal }
    { amount: uint, expiry: uint })

(define-map vaulted-tokens
    { address: principal }
    { amount: uint, release-height: uint })

(define-map voting-rights
    { member: principal }
    { voting-power: uint, last-vote-height: uint })

(define-map blocked-users 
    { address: principal } 
    { blocked-at: uint })

(define-map issuance-roles 
    { address: principal } 
    { can-issue: bool, issue-limit: uint })

;; ========================================
;; Private Helper Functions
;; ========================================

(define-private (is-admin)
    (is-eq tx-sender (var-get contract-admin)))

(define-private (is-valid-recipient (recipient principal))
    (and 
        (not (is-eq recipient tx-sender))
        (not (is-eq recipient (as-contract tx-sender)))
        (not (is-blocked recipient))
        (not (is-eq recipient (var-get contract-admin)))))

(define-private (is-blocked (address principal))
    (match (map-get? blocked-users { address: address })
        block-data true
        false))

(define-private (check-setup)
    (if (var-get is-setup)
        (ok true)
        NOT-SETUP))

(define-private (check-not-frozen)
    (if (not (var-get is-frozen))
        (ok true)
        CONTRACT-FROZEN))

(define-private (safe-add (a uint) (b uint))
    (let ((sum (+ a b)))
        (if (>= sum a)
            (ok sum)
            ARITHMETIC-ERROR)))

;; Event emission functions
(define-private (emit-transfer-event (from principal) (to principal) (amount uint))
    (begin
        (var-set last-event-sequence (+ (var-get last-event-sequence) u1))
        (print { event-type: "transfer", 
                 sequence: (var-get last-event-sequence), 
                 sender: from, 
                 recipient: to, 
                 amount: amount })))

(define-private (emit-issue-event (to principal) (amount uint))
    (begin
        (var-set last-event-sequence (+ (var-get last-event-sequence) u1))
        (print { event-type: "issue", 
                 sequence: (var-get last-event-sequence), 
                 recipient: to, 
                 amount: amount })))

(define-private (emit-burn-event (from principal) (amount uint))
    (begin
        (var-set last-event-sequence (+ (var-get last-event-sequence) u1))
        (print { event-type: "burn", 
                 sequence: (var-get last-event-sequence), 
                 from: from, 
                 amount: amount })))

;; ========================================
;; Read-Only Functions
;; ========================================

(define-read-only (get-name)
    (ok (var-get token-name)))

(define-read-only (get-symbol)
    (ok (var-get token-symbol)))

(define-read-only (get-decimals)
    (ok (var-get token-decimals)))

(define-read-only (get-total-supply)
    (ok (var-get total-supply)))

(define-read-only (get-balance (account principal))
    (ok (ft-get-balance nebula account)))

(define-read-only (get-approval (owner principal) (spender principal))
    (match (map-get? approvals { owner: owner, spender: spender })
        approval-data (let ((current-height block-height))
            (if (>= current-height (get expiry approval-data))
                (ok u0)
                (ok (get amount approval-data))))
        (ok u0)))

(define-read-only (is-vaulted (address principal))
    (match (map-get? vaulted-tokens { address: address })
        vault-data (> (get release-height vault-data) block-height)
        false))

;; ========================================
;; Administrative Functions
;; ========================================

(define-public (setup (name (string-ascii 32)) (symbol (string-ascii 10)) (decimals uint))
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (asserts! (not (var-get is-setup)) ALREADY-SETUP)
        
        ;; Validate name
        (asserts! (>= (len name) u1) INVALID-PARAMETER)
        (asserts! (<= (len name) u32) INVALID-PARAMETER)
        
        ;; Validate symbol
        (asserts! (>= (len symbol) u1) INVALID-PARAMETER)
        (asserts! (<= (len symbol) u10) INVALID-PARAMETER)
        
        ;; Validate decimals
        (asserts! (<= decimals u18) INVALID-PARAMETER)
        (asserts! (>= decimals u0) INVALID-PARAMETER)
        
        ;; Set values
        (var-set token-name name)
        (var-set token-symbol symbol)
        (var-set token-decimals decimals)
        (var-set is-setup true)
        
        ;; Emit setup event
        (print { event-type: "setup", 
                 name: name, 
                 symbol: symbol, 
                 decimals: decimals })
        (ok true)))

(define-public (set-admin (new-admin principal))
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (asserts! (not (is-eq new-admin (var-get contract-admin))) RECIPIENT-ERROR)
        
        (var-set contract-admin new-admin)
        (print { event-type: "admin-change", 
                 new-admin: new-admin })
        (ok true)))

(define-public (freeze)
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (var-set is-frozen true)
        (print { event-type: "contract-freeze" })
        (ok true)))

(define-public (unfreeze)
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (var-set is-frozen false)
        (print { event-type: "contract-unfreeze" })
        (ok true)))

(define-public (block-address (address principal))
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (asserts! (not (is-eq address (var-get contract-admin))) INVALID-PARAMETER)
        
        (map-set blocked-users 
            { address: address } 
            { blocked-at: block-height })
        (print { event-type: "address-blocked", 
                 address: address })
        (ok true)))


;; ========================================
;; Token Operations
;; ========================================

(define-public (issue (amount uint) (recipient principal))
    (begin
        (asserts! (is-admin) ACCESS-DENIED)
        (asserts! (> amount u0) INVALID-PARAMETER)
        (asserts! (is-valid-recipient recipient) RECIPIENT-ERROR)
        (try! (check-setup))
        (try! (check-not-frozen))
        
        (let ((new-supply (try! (safe-add (var-get total-supply) amount))))
            (asserts! (<= new-supply TOKEN-MAX-SUPPLY) SUPPLY-LIMIT-REACHED)
            
            (try! (ft-mint? nebula amount recipient))
            (var-set total-supply new-supply)
            
            ;; Update voting rights
            (map-set voting-rights
                { member: recipient }
                { 
                    voting-power: (unwrap! (safe-add 
                        (default-to u0 (get voting-power (map-get? voting-rights { member: recipient }))) 
                        amount) ARITHMETIC-ERROR),
                    last-vote-height: block-height 
                })
                
            ;; Emit event
            (emit-issue-event recipient amount)
            (ok true))))

(define-public (transfer (amount uint) (recipient principal))
    (begin
        (asserts! (> amount u0) INVALID-PARAMETER)
        (asserts! (is-valid-recipient recipient) RECIPIENT-ERROR)
        (try! (check-setup))
        (try! (check-not-frozen))
        (asserts! (not (is-vaulted tx-sender)) ACCESS-DENIED)
        
        (let ((sender-balance (unwrap! (get-balance tx-sender) BALANCE-TOO-LOW)))
            (asserts! (>= sender-balance amount) BALANCE-TOO-LOW)
            
            ;; Perform transfer
            (try! (ft-transfer? nebula amount tx-sender recipient))
            
            ;; Update voting rights for sender
            (map-set voting-rights
                { member: tx-sender }
                { 
                    voting-power: (- sender-balance amount),
                    last-vote-height: block-height 
                })
            
            ;; Update voting rights for recipient    
            (map-set voting-rights
                { member: recipient }
                { 
                    voting-power: (unwrap! (safe-add 
                        (default-to u0 (get voting-power (map-get? voting-rights { member: recipient }))) 
                        amount) ARITHMETIC-ERROR),
                    last-vote-height: block-height 
                })
                
            ;; Emit event
            (emit-transfer-event tx-sender recipient amount)
            (ok true))))

(define-public (approve (amount uint) (spender principal) (expiry uint))
    (begin
        (asserts! (> amount u0) INVALID-PARAMETER)
        (asserts! (not (is-eq spender tx-sender)) SPENDER-ERROR)
        (asserts! (>= expiry block-height) APPROVAL-EXPIRED)
        (try! (check-setup))
        (try! (check-not-frozen))
        
        ;; Set approval
        (map-set approvals
            { owner: tx-sender, spender: spender }
            { amount: amount, expiry: expiry })
            
        ;; Emit event
        (print { event-type: "approval", 
                 owner: tx-sender, 
                 spender: spender, 
                 amount: amount,
                 expiry: expiry })
        (ok true)))

(define-public (burn (amount uint))
    (begin
        (asserts! (> amount u0) INVALID-PARAMETER)
        (try! (check-setup))
        (try! (check-not-frozen))
        
        (let ((sender-balance (unwrap! (get-balance tx-sender) BALANCE-TOO-LOW)))
            (asserts! (>= sender-balance amount) BALANCE-TOO-LOW)
            
            ;; Perform burn
            (try! (ft-burn? nebula amount tx-sender))
            (var-set total-supply (- (var-get total-supply) amount))
            
            ;; Update voting rights
            (map-set voting-rights
                { member: tx-sender }
                { 
                    voting-power: (- sender-balance amount),
                    last-vote-height: block-height 
                })
                
            ;; Emit event
            (emit-burn-event tx-sender amount)
            (ok true))))

;; ========================================
;; Vault Management
;; ========================================

(define-public (vault-tokens (amount uint) (lock-period uint))
    (begin
        (asserts! (> amount u0) INVALID-PARAMETER)
        (asserts! (> lock-period u0) INVALID-PARAMETER)
        (try! (check-setup))
        (try! (check-not-frozen))
        
        (let ((sender-balance (unwrap! (get-balance tx-sender) BALANCE-TOO-LOW))
              (release-block (+ block-height lock-period)))
            (asserts! (>= sender-balance amount) BALANCE-TOO-LOW)
            
            ;; Store vault information
            (map-set vaulted-tokens
                { address: tx-sender }
                { amount: amount, release-height: release-block })
                
            ;; Emit event
            (print { event-type: "tokens-vaulted", 
                     address: tx-sender, 
                     amount: amount, 
                     release-height: release-block })
            (ok true))))

