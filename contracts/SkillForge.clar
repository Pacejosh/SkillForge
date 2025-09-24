;; SkillForge - Decentralized skill verification and badge earning platform
;; Version: 1.0.0

(define-data-var platform-admin principal tx-sender)
(define-data-var total-verified-skills uint u0)
(define-data-var badge-reward-rate uint u50) ;; badges per verified skill
(define-data-var current-verification-round uint u0)

(define-map learner-achievements principal uint)
(define-map learner-specializations principal (string-utf8 64))
(define-map skill-categories (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-admin (err u2100))
(define-constant err-admin-already-set (err u2101))
(define-constant err-invalid-skill-count (err u2102))
(define-constant err-no-badges-available (err u2103))
(define-constant err-no-achievements (err u2104))
(define-constant err-invalid-category (err u2105))
(define-constant err-category-not-active (err u2106))

;; Verify admin authorization
(define-private (is-platform-admin (caller principal))
  (begin
    (asserts! (is-eq caller (var-get platform-admin)) err-unauthorized-admin)
    (ok true)))

;; Initialize skill verification platform
(define-public (initialize-skill-platform (admin principal))
  (begin
    (asserts! (is-none (map-get? learner-achievements admin)) err-admin-already-set)
    (var-set platform-admin admin)
    (ok "SkillForge platform initialized successfully")))

;; Activate skill category
(define-public (activate-skill-category (category-name (string-utf8 64)))
  (begin
    (try! (is-platform-admin tx-sender))
    (asserts! (> (len category-name) u0) err-invalid-category)
    (map-set skill-categories category-name true)
    (ok "Skill category activated")))

;; Record verified skills
(define-public (record-verified-skills (skill-count uint) (specialization (string-utf8 64)))
  (begin
    (asserts! (> skill-count u0) err-invalid-skill-count)
    (asserts! (default-to false (map-get? skill-categories specialization)) err-category-not-active)
    
    (let ((current-achievements (default-to u0 (map-get? learner-achievements tx-sender))))
      (map-set learner-achievements tx-sender (+ current-achievements skill-count))
      (map-set learner-specializations tx-sender specialization)
      (var-set total-verified-skills (+ (var-get total-verified-skills) skill-count))
      (ok (+ current-achievements skill-count)))))

;; Process badge distribution
(define-public (process-badge-distribution)
  (begin
    (try! (is-platform-admin tx-sender))
    (let ((current-round (+ (var-get current-verification-round) u1))
          (total-skills (var-get total-verified-skills)))
      (asserts! (> total-skills (var-get current-verification-round)) err-no-badges-available)
      
      (let ((new-badges (* (var-get badge-reward-rate) total-skills)))
        (var-set current-verification-round current-round)
        (ok new-badges)))))

;; Claim skill badges
(define-public (claim-skill-badges)
  (begin
    (let ((learner-skills (default-to u0 (map-get? learner-achievements tx-sender))))
      (asserts! (> learner-skills u0) err-no-achievements)
      
      (let ((total-skills (var-get total-verified-skills))
            (badge-points (* (var-get badge-reward-rate) learner-skills))
            (achievement-ratio (/ (* learner-skills u100000) total-skills)))
        
        (let ((final-badges (/ (* achievement-ratio badge-points) u100000)))
          (map-delete learner-achievements tx-sender)
          (map-delete learner-specializations tx-sender)
          (var-set total-verified-skills (- (var-get total-verified-skills) learner-skills))
          (ok (+ learner-skills final-badges)))))))

;; Read-only functions
(define-read-only (get-learner-achievements (learner principal))
  (default-to u0 (map-get? learner-achievements learner)))

(define-read-only (get-learner-specialization (learner principal))
  (map-get? learner-specializations learner))

(define-read-only (get-total-verified-skills)
  (var-get total-verified-skills))

(define-read-only (is-category-active (category-name (string-utf8 64)))
  (default-to false (map-get? skill-categories category-name)))

(define-read-only (get-platform-overview)
  {
    admin: (var-get platform-admin),
    total-skills: (var-get total-verified-skills),
    badge-rate: (var-get badge-reward-rate)
  })
