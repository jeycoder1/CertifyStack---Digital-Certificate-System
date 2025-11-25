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