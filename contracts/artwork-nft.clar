;; Artwork NFT Contract

(define-non-fungible-token artwork-nft uint)

(define-data-var last-token-id uint u0)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

(define-map token-uris {token-id: uint} {uri: (string-utf8 256)})
(define-map artwork-info
  {token-id: uint}
  {
    artist: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    creation-date: uint,
    royalty-percentage: uint
  }
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

(define-public (mint (recipient principal) (uri (string-utf8 256)) (title (string-utf8 100)) (description (string-utf8 500)) (royalty-percentage uint))
  (let
    ((token-id (+ (var-get last-token-id) u1)))
    (try! (nft-mint? artwork-nft token-id recipient))
    (map-set token-uris {token-id: token-id} {uri: uri})
    (map-set artwork-info
      {token-id: token-id}
      {
        artist: recipient,
        title: title,
        description: description,
        creation-date: block-height,
        royalty-percentage: royalty-percentage
      }
    )
    (var-set last-token-id token-id)
    (ok token-id)))

(define-read-only (get-token-uri (token-id uint))
  (ok (get uri (unwrap! (map-get? token-uris {token-id: token-id}) err-not-found))))

(define-read-only (get-artwork-info (token-id uint))
  (ok (unwrap! (map-get? artwork-info {token-id: token-id}) err-not-found)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-unauthorized)
    (nft-transfer? artwork-nft token-id sender recipient)))

(define-public (set-artwork-info (token-id uint) (new-title (string-utf8 100)) (new-description (string-utf8 500)))
  (let ((current-info (unwrap! (map-get? artwork-info {token-id: token-id}) err-not-found)))
    (asserts! (is-eq tx-sender (get artist current-info)) err-unauthorized)
    (ok (map-set artwork-info
      {token-id: token-id}
      (merge current-info {
        title: new-title,
        description: new-description
      })))))

