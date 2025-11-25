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