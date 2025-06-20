;; Decentralized Job Board Smart Contract
;; A comprehensive blockchain-based employment platform that enables employers to post job opportunities,
;; manage applications, and facilitate transparent hiring processes. Job seekers can browse listings,
;; submit applications with cover letters, and track application status in a trustless environment.
;; Features include job posting management, application tracking, and employer-controlled hiring workflows.

;; DATA STRUCTURES AND STORAGE

;; Core job posting information storage
(define-map job-postings-registry
  { posting-identifier: uint }
  { 
    employer-principal: principal,
    position-title: (string-ascii 100),
    role-description: (string-ascii 1000),
    compensation-amount: uint,
    is-posting-active: bool,
    creation-block-height: uint,
    last-modification-height: uint 
  })

;; Comprehensive application tracking system
(define-map candidate-applications-registry
  { posting-identifier: uint, candidate-principal: principal }
  { 
    cover-letter-content: (string-ascii 1000),
    current-application-status: (string-ascii 20),
    submission-block-height: uint 
  })

;; Global posting counter for unique identifiers
(define-data-var total-postings-created uint u0)

;; Application metrics per job posting
(define-map posting-application-metrics 
  { posting-identifier: uint } 
  { total-applications-received: uint })

;; ERROR HANDLING CONSTANTS

(define-constant err-invalid-compensation-amount u1)
(define-constant err-posting-not-found u2)
(define-constant err-posting-inactive u3)
(define-constant err-unauthorized-access u4)
(define-constant err-duplicate-application-submission u5)
(define-constant err-invalid-posting-identifier u6)
(define-constant err-invalid-status-transition u7)
(define-constant err-invalid-input-parameters u8)

;; VALIDATION UTILITIES

;; Comprehensive string input validation
(define-private (validate-string-input (input-string (string-ascii 1000)))
  (and 
    (> (len input-string) u0) 
    (<= (len input-string) u1000)))

;; Job posting identifier validation
(define-private (validate-posting-identifier (posting-id uint))
  (and 
    (> posting-id u0) 
    (<= posting-id (var-get total-postings-created))))

;; Application status validation
(define-private (validate-application-status (status-value (string-ascii 20)))
  (or 
    (is-eq status-value "pending-review")
    (is-eq status-value "accepted")
    (is-eq status-value "rejected")
    (is-eq status-value "under-consideration")))

;; JOB POSTING MANAGEMENT FUNCTIONS

;; Create new job posting with comprehensive validation
(define-public (create-new-job-posting 
  (position-title (string-ascii 100)) 
  (role-description (string-ascii 1000)) 
  (compensation-amount uint))
  (begin
    ;; Validate all input parameters
    (asserts! (validate-string-input position-title) (err err-invalid-input-parameters))
    (asserts! (validate-string-input role-description) (err err-invalid-input-parameters))
    (asserts! (> compensation-amount u0) (err err-invalid-compensation-amount))
    
    (let ((new-posting-id (+ (var-get total-postings-created) u1)))
      ;; Store job posting data
      (map-set job-postings-registry
        { posting-identifier: new-posting-id }
        { 
          employer-principal: tx-sender,
          position-title: position-title,
          role-description: role-description,
          compensation-amount: compensation-amount,
          is-posting-active: true,
          creation-block-height: block-height,
          last-modification-height: block-height 
        })
      
      ;; Initialize application metrics
      (map-set posting-application-metrics 
        { posting-identifier: new-posting-id } 
        { total-applications-received: u0 })
      
      ;; Update global counter
      (var-set total-postings-created new-posting-id)
      (ok new-posting-id))))

;; Modify existing job posting details
(define-public (modify-job-posting-details 
  (posting-id uint) 
  (updated-position-title (string-ascii 100)) 
  (updated-role-description (string-ascii 1000)) 
  (updated-compensation-amount uint))
  (begin
    ;; Validate input parameters
    (asserts! (validate-posting-identifier posting-id) (err err-invalid-posting-identifier))
    (asserts! (validate-string-input updated-position-title) (err err-invalid-input-parameters))
    (asserts! (validate-string-input updated-role-description) (err err-invalid-input-parameters))
    (asserts! (> updated-compensation-amount u0) (err err-invalid-compensation-amount))
    
    (let ((existing-posting-data (map-get? job-postings-registry { posting-identifier: posting-id })))
      (asserts! (is-some existing-posting-data) (err err-posting-not-found))
      
      (let ((posting-details (unwrap-panic existing-posting-data)))
        ;; Verify employer authorization
        (asserts! (is-eq (get employer-principal posting-details) tx-sender) (err err-unauthorized-access))
        (asserts! (get is-posting-active posting-details) (err err-posting-inactive))
        
        ;; Update posting information
        (map-set job-postings-registry
          { posting-identifier: posting-id }
          (merge posting-details { 
            position-title: updated-position-title,
            role-description: updated-role-description,
            compensation-amount: updated-compensation-amount,
            last-modification-height: block-height
          }))
        (ok true)))))

;; Deactivate job posting
(define-public (deactivate-job-posting (posting-id uint))
  (begin
    (asserts! (validate-posting-identifier posting-id) (err err-invalid-posting-identifier))
    
    (let ((existing-posting-data (map-get? job-postings-registry { posting-identifier: posting-id })))
      (asserts! (is-some existing-posting-data) (err err-posting-not-found))
      
      (let ((posting-details (unwrap-panic existing-posting-data)))
        (asserts! (is-eq (get employer-principal posting-details) tx-sender) (err err-unauthorized-access))
        
        (map-set job-postings-registry
          { posting-identifier: posting-id }
          (merge posting-details { 
            is-posting-active: false,
            last-modification-height: block-height 
          }))
        (ok true)))))

;; APPLICATION MANAGEMENT FUNCTIONS

;; Submit job application with cover letter
(define-public (submit-candidate-application 
  (posting-id uint) 
  (cover-letter-content (string-ascii 1000)))
  (begin
    ;; Validate input parameters
    (asserts! (validate-posting-identifier posting-id) (err err-invalid-posting-identifier))
    (asserts! (validate-string-input cover-letter-content) (err err-invalid-input-parameters))
    
    (let ((target-posting-data (map-get? job-postings-registry { posting-identifier: posting-id })))
      (asserts! (is-some target-posting-data) (err err-posting-not-found))
      (asserts! (get is-posting-active (unwrap-panic target-posting-data)) (err err-posting-inactive))
      
      ;; Prevent duplicate applications
      (asserts! (is-none (map-get? candidate-applications-registry 
                                  { posting-identifier: posting-id, candidate-principal: tx-sender })) 
                (err err-duplicate-application-submission))
      
      ;; Create application record
      (map-set candidate-applications-registry
        { posting-identifier: posting-id, candidate-principal: tx-sender }
        { 
          cover-letter-content: cover-letter-content,
          current-application-status: "pending-review",
          submission-block-height: block-height 
        })
      
      ;; Update application metrics
      (match (map-get? posting-application-metrics { posting-identifier: posting-id })
        existing-metrics 
          (map-set posting-application-metrics
            { posting-identifier: posting-id }
            { total-applications-received: (+ (get total-applications-received existing-metrics) u1) })
        (map-set posting-application-metrics 
          { posting-identifier: posting-id } 
          { total-applications-received: u1 }))
      
      (ok true))))

;; Update candidate application status
(define-public (update-candidate-application-status 
  (posting-id uint) 
  (candidate-principal principal) 
  (new-status (string-ascii 20)))
  (begin
    ;; Validate input parameters
    (asserts! (validate-posting-identifier posting-id) (err err-invalid-posting-identifier))
    (asserts! (not (is-eq candidate-principal tx-sender)) (err err-invalid-input-parameters))
    (asserts! (validate-string-input new-status) (err err-invalid-input-parameters))
    (asserts! (validate-application-status new-status) (err err-invalid-status-transition))
    
    (let ((target-posting-data (map-get? job-postings-registry { posting-identifier: posting-id }))
          (existing-application-data (map-get? candidate-applications-registry 
                                             { posting-identifier: posting-id, candidate-principal: candidate-principal })))
      
      (asserts! (is-some target-posting-data) (err err-posting-not-found))
      (asserts! (is-eq (get employer-principal (unwrap-panic target-posting-data)) tx-sender) (err err-unauthorized-access))
      (asserts! (is-some existing-application-data) (err err-posting-not-found))
      
      ;; Update application status
      (map-set candidate-applications-registry
        { posting-identifier: posting-id, candidate-principal: candidate-principal }
        (merge (unwrap-panic existing-application-data) { current-application-status: new-status }))
      
      (ok true))))

;; READ-ONLY QUERY FUNCTIONS

;; Retrieve comprehensive job posting information
(define-read-only (get-job-posting-information (posting-id uint))
  (map-get? job-postings-registry { posting-identifier: posting-id }))

;; Retrieve candidate application details
(define-read-only (get-candidate-application-details (posting-id uint) (candidate-principal principal))
  (map-get? candidate-applications-registry { posting-identifier: posting-id, candidate-principal: candidate-principal }))

;; Get total number of job postings created
(define-read-only (get-total-job-postings-count)
  (var-get total-postings-created))

;; Get application statistics for specific job posting
(define-read-only (get-posting-application-statistics (posting-id uint))
  (match (map-get? posting-application-metrics { posting-identifier: posting-id })
    metrics-data (ok (get total-applications-received metrics-data))
    (err err-posting-not-found)))

;; Check if job posting is currently active
(define-read-only (is-job-posting-active (posting-id uint))
  (match (map-get? job-postings-registry { posting-identifier: posting-id })
    posting-data (ok (get is-posting-active posting-data))
    (err err-posting-not-found)))

;; Verify employer ownership of job posting
(define-read-only (verify-employer-ownership (posting-id uint) (employer-address principal))
  (match (map-get? job-postings-registry { posting-identifier: posting-id })
    posting-data (ok (is-eq (get employer-principal posting-data) employer-address))
    (err err-posting-not-found)))