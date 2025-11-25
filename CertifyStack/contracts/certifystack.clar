;; CertifyStack - Digital Certificate and Badge Verification System
;; Issues and verifies educational certificates using smart contracts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-issued (err u103))
(define-constant err-invalid-expiry (err u104))
(define-constant err-certificate-revoked (err u105))
(define-constant err-invalid-parameters (err u106))
(define-constant err-limit-reached (err u107))

;; Data Variables
(define-data-var certificate-nonce uint u0)
(define-data-var badge-nonce uint u0)
(define-data-var endorsement-nonce uint u0)

;; Data Maps
(define-map certificates
    uint
    {
        recipient: principal,
        issuer: principal,
        title: (string-ascii 100),
        competency: (string-ascii 100),
        issue-date: uint,
        expiry-date: (optional uint),
        revoked: bool,
        metadata-uri: (string-ascii 256)
    }
)

(define-map badges
    uint
    {
        recipient: principal,
        issuer: principal,
        badge-name: (string-ascii 100),
        criteria: (string-ascii 200),
        issue-date: uint,
        badge-uri: (string-ascii 256)
    }
)

(define-map endorsements
    uint
    {
        certificate-id: uint,
        endorser: principal,
        endorsement-text: (string-ascii 200),
        timestamp: uint
    }
)

(define-map recipient-certificates
    principal
    (list 50 uint)
)

(define-map recipient-badges
    principal
    (list 50 uint)
)

(define-map certificate-endorsements
    uint
    (list 20 uint)
)

(define-map authorized-issuers
    principal
    { authorized: bool, institution: (string-ascii 100) }
)

(define-map certificate-transfers
    uint
    (list 10 principal)
)

;; Initialize owner as authorized issuer
(map-set authorized-issuers contract-owner { authorized: true, institution: "Platform Admin" })

;; #[allow(unchecked_data)]
;; Issue a new certificate
(define-public (issue-certificate 
    (recipient principal) 
    (title (string-ascii 100)) 
    (competency (string-ascii 100))
    (expiry-date (optional uint))
    (metadata-uri (string-ascii 256)))
    (let
        (
            (cert-id (var-get certificate-nonce))
            (issuer-info (unwrap! (map-get? authorized-issuers tx-sender) err-unauthorized))
            (recipient-certs (default-to (list) (map-get? recipient-certificates recipient)))
        )
        (asserts! (get authorized issuer-info) err-unauthorized)
        (map-set certificates cert-id {
            recipient: recipient,
            issuer: tx-sender,
            title: title,
            competency: competency,
            issue-date: stacks-block-height,
            expiry-date: expiry-date,
            revoked: false,
            metadata-uri: metadata-uri
        })
        (map-set recipient-certificates recipient (unwrap-panic (as-max-len? (append recipient-certs cert-id) u50)))
        (var-set certificate-nonce (+ cert-id u1))
        (ok cert-id)
    )
)

;; #[allow(unchecked_data)]
;; Issue a badge to a recipient
(define-public (issue-badge
    (recipient principal)
    (badge-name (string-ascii 100))
    (criteria (string-ascii 200))
    (badge-uri (string-ascii 256)))
    (let
        (
            (badge-id (var-get badge-nonce))
            (issuer-info (unwrap! (map-get? authorized-issuers tx-sender) err-unauthorized))
            (recipient-badge-list (default-to (list) (map-get? recipient-badges recipient)))
        )
        (asserts! (get authorized issuer-info) err-unauthorized)
        (map-set badges badge-id {
            recipient: recipient,
            issuer: tx-sender,
            badge-name: badge-name,
            criteria: criteria,
            issue-date: stacks-block-height,
            badge-uri: badge-uri
        })
        (map-set recipient-badges recipient (unwrap-panic (as-max-len? (append recipient-badge-list badge-id) u50)))
        (var-set badge-nonce (+ badge-id u1))
        (ok badge-id)
    )
)

;; #[allow(unchecked_data)]
;; Batch issue certificates
(define-public (batch-issue-certificates
    (recipients (list 10 principal))
    (title (string-ascii 100))
    (competency (string-ascii 100))
    (expiry-date (optional uint))
    (metadata-uri (string-ascii 256)))
    (let
        (
            (issuer-info (unwrap! (map-get? authorized-issuers tx-sender) err-unauthorized))
        )
        (asserts! (get authorized issuer-info) err-unauthorized)
        (ok (map issue-certificate-helper recipients))
    )
)

;; #[allow(unchecked_data)]
;; Helper function for batch issuing
(define-private (issue-certificate-helper (recipient principal))
    (let
        (
            (cert-id (var-get certificate-nonce))
            (recipient-certs (default-to (list) (map-get? recipient-certificates recipient)))
        )
        (map-set certificates cert-id {
            recipient: recipient,
            issuer: tx-sender,
            title: "Batch Certificate",
            competency: "Multiple Competencies",
            issue-date: stacks-block-height,
            expiry-date: none,
            revoked: false,
            metadata-uri: ""
        })
        (map-set recipient-certificates recipient (unwrap-panic (as-max-len? (append recipient-certs cert-id) u50)))
        (var-set certificate-nonce (+ cert-id u1))
        cert-id
    )
)

;; #[allow(unchecked_data)]
;; Add an endorsement to a certificate
(define-public (endorse-certificate
    (cert-id uint)
    (endorsement-text (string-ascii 200)))
    (let
        (
            (cert (unwrap! (map-get? certificates cert-id) err-not-found))
            (endorsement-id (var-get endorsement-nonce))
            (cert-endorsements (default-to (list) (map-get? certificate-endorsements cert-id)))
        )
        (asserts! (not (get revoked cert)) err-certificate-revoked)
        (map-set endorsements endorsement-id {
            certificate-id: cert-id,
            endorser: tx-sender,
            endorsement-text: endorsement-text,
            timestamp: stacks-block-height
        })
        (map-set certificate-endorsements cert-id (unwrap-panic (as-max-len? (append cert-endorsements endorsement-id) u20)))
        (var-set endorsement-nonce (+ endorsement-id u1))
        (ok endorsement-id)
    )
)

;; Revoke a certificate
(define-public (revoke-certificate (cert-id uint))
    (let
        (
            (cert (unwrap! (map-get? certificates cert-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get issuer cert)) err-unauthorized)
        (ok (map-set certificates cert-id (merge cert { revoked: true })))
    )
)

;; #[allow(unchecked_data)]
;; Update certificate metadata URI
(define-public (update-certificate-metadata
    (cert-id uint)
    (new-metadata-uri (string-ascii 256)))
    (let
        (
            (cert (unwrap! (map-get? certificates cert-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get issuer cert)) err-unauthorized)
        (asserts! (not (get revoked cert)) err-certificate-revoked)
        (ok (map-set certificates cert-id (merge cert { metadata-uri: new-metadata-uri })))
    )
)

;; #[allow(unchecked_data)]
;; Transfer certificate ownership
(define-public (transfer-certificate
    (cert-id uint)
    (new-recipient principal))
    (let
        (
            (cert (unwrap! (map-get? certificates cert-id) err-not-found))
            (old-recipient (get recipient cert))
            (transfer-history (default-to (list) (map-get? certificate-transfers cert-id)))
        )
        (asserts! (is-eq tx-sender old-recipient) err-unauthorized)
        (asserts! (not (get revoked cert)) err-certificate-revoked)
        (map-set certificates cert-id (merge cert { recipient: new-recipient }))
        (map-set certificate-transfers cert-id (unwrap-panic (as-max-len? (append transfer-history old-recipient) u10)))
        (ok true)
    )
)

;; #[allow(unchecked_data)]
;; Add authorized issuer
(define-public (add-issuer (issuer principal) (institution (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-issuers issuer { authorized: true, institution: institution }))
    )
)

;; #[allow(unchecked_data)]
;; Remove authorized issuer
(define-public (remove-issuer (issuer principal))
    (let
        (
            (issuer-info (unwrap! (map-get? authorized-issuers issuer) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-issuers issuer (merge issuer-info { authorized: false })))
    )
)