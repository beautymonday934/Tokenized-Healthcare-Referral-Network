;; Provider Verification Contract
;; This contract validates healthcare practitioners

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    license-number: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

;; Add a new provider (admin only)
(define-public (register-provider (provider principal) (name (string-utf8 100)) (license-number (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? providers { provider-id: provider })) (err u100))
    (map-set providers
      { provider-id: provider }
      {
        name: name,
        license-number: license-number,
        status: u0,
        verification-date: u0
      }
    )
    (ok true)
  )
)

;; Verify a provider (admin only)
(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? providers { provider-id: provider })
      provider-data (begin
        (map-set providers
          { provider-id: provider }
          (merge provider-data {
            status: u1,
            verification-date: block-height
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Suspend a provider (admin only)
(define-public (suspend-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? providers { provider-id: provider })
      provider-data (begin
        (map-set providers
          { provider-id: provider }
          (merge provider-data { status: u2 })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Check if a provider is verified
(define-read-only (is-provider-verified (provider principal))
  (match (map-get? providers { provider-id: provider })
    provider-data (is-eq (get status provider-data) u1)
    false
  )
)

;; Get provider details
(define-read-only (get-provider-details (provider principal))
  (map-get? providers { provider-id: provider })
)

;; Transfer admin rights (admin only)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
