;; Exhibition Access Token Contract

(define-fungible-token exhibition-access-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))

(define-map exhibition-prices {exhibition-id: uint} {price: uint})

(define-public (set-exhibition-price (exhibition-id uint) (price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set exhibition-prices {exhibition-id: exhibition-id} {price: price}))))

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? exhibition-access-token amount recipient)))

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-authorized)
    (ft-transfer? exhibition-access-token amount sender recipient)))

(define-public (buy-exhibition-access (exhibition-id uint))
  (let
    ((price (get price (unwrap! (map-get? exhibition-prices {exhibition-id: exhibition-id}) err-not-authorized))))
    (try! (ft-transfer? exhibition-access-token price tx-sender contract-owner))
    (ok true)))

(define-read-only (get-balance (account principal))
  (ok (ft-get-balance exhibition-access-token account)))

