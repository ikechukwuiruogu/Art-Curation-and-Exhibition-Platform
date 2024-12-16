;; Exhibition Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

(define-map exhibitions
  {exhibition-id: uint}
  {
    theme: (string-utf8 100),
    curator: principal,
    start-date: uint,
    end-date: uint,
    artwork-ids: (list 100 uint),
    status: (string-ascii 20)
  }
)

(define-map votes
  {exhibition-id: uint, voter: principal}
  {artwork-id: uint}
)

(define-data-var last-exhibition-id uint u0)

(define-public (propose-exhibition (theme (string-utf8 100)) (start-date uint) (end-date uint))
  (let
    ((exhibition-id (+ (var-get last-exhibition-id) u1)))
    (map-set exhibitions
      {exhibition-id: exhibition-id}
      {
        theme: theme,
        curator: tx-sender,
        start-date: start-date,
        end-date: end-date,
        artwork-ids: (list),
        status: "proposed"
      }
    )
    (var-set last-exhibition-id exhibition-id)
    (ok exhibition-id)))

(define-public (vote-for-artwork (exhibition-id uint) (artwork-id uint))
  (let
    ((exhibition (unwrap! (map-get? exhibitions {exhibition-id: exhibition-id}) err-not-found)))
    (asserts! (is-eq (get status exhibition) "voting") err-unauthorized)
    (map-set votes
      {exhibition-id: exhibition-id, voter: tx-sender}
      {artwork-id: artwork-id}
    )
    (ok true)))

(define-read-only (get-exhibition (exhibition-id uint))
  (ok (unwrap! (map-get? exhibitions {exhibition-id: exhibition-id}) err-not-found)))

(define-public (start-voting (exhibition-id uint))
  (let
    ((exhibition (unwrap! (map-get? exhibitions {exhibition-id: exhibition-id}) err-not-found)))
    (asserts! (is-eq tx-sender (get curator exhibition)) err-unauthorized)
    (asserts! (is-eq (get status exhibition) "proposed") err-unauthorized)
    (ok (map-set exhibitions
      {exhibition-id: exhibition-id}
      (merge exhibition {status: "voting"})))))

(define-public (end-voting (exhibition-id uint))
  (let
    ((exhibition (unwrap! (map-get? exhibitions {exhibition-id: exhibition-id}) err-not-found)))
    (asserts! (is-eq tx-sender (get curator exhibition)) err-unauthorized)
    (asserts! (is-eq (get status exhibition) "voting") err-unauthorized)
    (ok (map-set exhibitions
      {exhibition-id: exhibition-id}
      (merge exhibition {status: "curated"})))))

(define-public (add-artwork-to-exhibition (exhibition-id uint) (artwork-id uint))
  (let
    ((exhibition (unwrap! (map-get? exhibitions {exhibition-id: exhibition-id}) err-not-found)))
    (asserts! (is-eq tx-sender (get curator exhibition)) err-unauthorized)
    (asserts! (is-eq (get status exhibition) "curated") err-unauthorized)
    (let
      ((current-artworks (get artwork-ids exhibition))
       (new-artworks (unwrap! (as-max-len? (append current-artworks artwork-id) u100) err-unauthorized)))
      (ok (map-set exhibitions
        {exhibition-id: exhibition-id}
        (merge exhibition {
          artwork-ids: new-artworks
        }))))))

