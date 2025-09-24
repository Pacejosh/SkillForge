# SkillForge

A decentralized skill verification and badge earning platform built on Stacks blockchain.

## Overview

SkillForge enables learners to verify their skills across different categories and earn badges based on their achievements. The platform provides a transparent and decentralized way to track skill development and reward learning progress.

## Features

- Skill verification tracking
- Category-based specializations
- Badge reward system
- Decentralized achievement records
- Admin-controlled skill categories

## Smart Contract Functions

### Public Functions
- `initialize-skill-platform` - Initialize the platform with an admin
- `activate-skill-category` - Activate new skill categories
- `record-verified-skills` - Record verified skills for learners
- `process-badge-distribution` - Process badge rewards
- `claim-skill-badges` - Claim earned badges

### Read-Only Functions
- `get-learner-achievements` - Get learner's total achievements
- `get-learner-specialization` - Get learner's specialization
- `get-total-verified-skills` - Get platform-wide skill count
- `is-category-active` - Check if skill category is active
- `get-platform-overview` - Get platform statistics

## Usage

Deploy the contract and initialize with an admin principal. Activate skill categories, then learners can record verified skills and claim badges based on their achievements.

## License

MIT
\`\`\`

```clarity file="contracts/eco-impact.clar"
;; EcoImpact - Environmental action tracking and carbon credit platform
;; Version: 1.0.0

(define-data-var environmental-coordinator principal tx-sender)
(define-data-var total-carbon-offset uint u0)
(define-data-var credit-conversion-rate uint u10) ;; credits per carbon unit
(define-data-var last-credit-cycle uint u0)

(define-map participant-offsets principal uint)
(define-map participant-actions principal (string-utf8 64))
(define-map action-types (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-coordinator (err u3100))
(define-constant err-coordinator-exists (err u3101))
(define-constant err-invalid-offset-amount (err u3102))
(define-constant err-no-credits-due (err u3103))
(define-constant err-no-participation (err u3104))
(define-constant err-invalid-action-type (err u3105))
(define-constant err-action-not-approved (err u3106))

;; Verify coordinator authorization
(define-private (is-environmental-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get environmental-coordinator)) err-unauthorized-coordinator)
    (ok true)))

;; Launch environmental impact program
(define-public (launch-eco-program (coordinator principal))
  (begin
    (asserts! (is-none (map-get? participant-offsets coordinator)) err-coordinator-exists)
    (var-set environmental-coordinator coordinator)
    (ok "EcoImpact program launched successfully")))

;; Approve environmental action type
(define-public (approve-action-type (action-name (string-utf8 64)))
  (begin
    (try! (is-environmental-coordinator tx-sender))
    (asserts! (> (len action-name) u0) err-invalid-action-type)
    (map-set action-types action-name true)
    (ok "Environmental action type approved")))

;; Record carbon offset activities
(define-public (record-carbon-offset (offset-amount uint) (action-type (string-utf8 64)))
  (begin
    (asserts! (> offset-amount u0) err-invalid-offset-amount)
    (asserts! (default-to false (map-get? action-types action-type)) err-action-not-approved)
    
    (let ((current-offset (default-to u0 (map-get? participant-offsets tx-sender))))
      (map-set participant-offsets tx-sender (+ current-offset offset-amount))
      (map-set participant-actions tx-sender action-type)
      (var-set total-carbon-offset (+ (var-get total-carbon-offset) offset-amount))
      (ok (+ current-offset offset-amount)))))

;; Calculate carbon credits
(define-public (calculate-carbon-credits)
  (begin
    (try! (is-environmental-coordinator tx-sender))
    (let ((current-cycle (+ (var-get last-credit-cycle) u1))
          (total-offset (var-get total-carbon-offset)))
      (asserts! (> total-offset (var-get last-credit-cycle)) err-no-credits-due)
      
      (let ((new-credits (* (var-get credit-conversion-rate) total-offset)))
        (var-set last-credit-cycle current-cycle)
        (ok new-credits)))))

;; Claim environmental credits
(define-public (claim-environmental-credits)
  (begin
    (let ((participant-offset (default-to u0 (map-get? participant-offsets tx-sender))))
      (asserts! (> participant-offset u0) err-no-participation)
      
      (let ((total-offset (var-get total-carbon-offset))
            (credit-points (* (var-get credit-conversion-rate) participant-offset))
            (participation-share (/ (* participant-offset u100000) total-offset)))
        
        (let ((final-credits (/ (* participation-share credit-points) u100000)))
          (map-delete participant-offsets tx-sender)
          (map-delete participant-actions tx-sender)
          (var-set total-carbon-offset (- (var-get total-carbon-offset) participant-offset))
          (ok (+ participant-offset final-credits)))))))

;; Read-only functions
(define-read-only (get-participant-offset (participant principal))
  (default-to u0 (map-get? participant-offsets participant)))

(define-read-only (get-participant-action (participant principal))
  (map-get? participant-actions participant))

(define-read-only (get-total-carbon-offset)
  (var-get total-carbon-offset))

(define-read-only (is-action-approved (action-name (string-utf8 64)))
  (default-to false (map-get? action-types action-name)))

(define-read-only (get-program-metrics)
  {
    coordinator: (var-get environmental-coordinator),
    total-offset: (var-get total-carbon-offset),
    credit-rate: (var-get credit-conversion-rate)
  })
