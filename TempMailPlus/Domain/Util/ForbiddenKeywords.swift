import Foundation

// Ported 1:1 from Android `domain/util/ForbiddenKeywords.kt`.
enum ForbiddenKeywords {
    static let list: [String] = [
        // Finance / Banks / Payment
        "bank", "finance", "loan", "credit", "debit", "mortgage", "insurance",
        "pay", "payment", "billing", "invoice", "refund", "transfer", "escrow",
        "remit", "wallet", "crypto", "bitcoin", "ether", "token", "airdrop",
        "investment", "invest", "stock", "fund", "trading", "broker",
        "visa", "mastercard", "unionpay", "jcb",
        "paypal", "venmo", "stripe", "cashapp", "square", "zelle",
        "alipay", "wechat", "paytm", "mpesa", "gcash",

        // Global bank brands (root words)
        "boa", "chase", "wells", "fargo", "citi", "hsbc", "barclays",
        "lloyds", "santander", "deutsche", "ubs", "ing", "rabobank",
        "natwest", "capitalone", "amex", "discover",
        "revolut", "n26", "monzo", "wise", "klarna", "adyen", "payoneer",
        "coinbase", "binance", "kraken", "gemini",

        // Asian banks (roots)
        "icbc", "uob", "ocbc", "dbs", "hdfc", "sbi", "kotak",
        "anz", "nab", "qnb", "emiratesnbd", "fab", "mashreq",

        // Tech giants
        "google", "gmail", "youtube", "android",
        "apple", "icloud", "microsoft", "windows", "outlook",
        "amazon", "aws", "netflix", "disney", "hulu", "tiktok",
        "instagram", "facebook", "meta", "whatsapp", "messenger",
        "telegram", "signal", "zoom", "slack",

        // Commerce / Brands
        "shopify", "salesforce", "zendesk",
        "ebay", "alibaba", "aliexpress", "shein", "temu",
        "walmart", "costco", "nike", "adidas", "puma",

        // Fraud / Scam / Official impersonation
        "admin", "administrator", "support", "helpdesk", "techsupport",
        "noreply", "no-reply", "security", "auth", "authentication",
        "official", "verify", "verification", "identity", "idcheck",
        "secure", "alert", "warning", "notice",
        "system", "account", "suspended", "locked", "unlock",
        "recovery", "reset", "password", "login", "update",
        "claims", "invoice", "billing", "refund", "chargeback",
        "wiretransfer", "transaction", "paymentfailed",

        // Authority / Government
        "gov", "government", "police", "customs", "immigration",
        "court", "judge", "irs", "tax", "audit",

        // Logistics / Courier impersonation
        "dhl", "fedex", "ups", "usps", "royalmail", "delivery",
        "shipping", "courier", "parcel", "logistics",

        // Emergency / High-risk terms
        "urgent", "sos", "emergency",

        // Corporate titles
        "ceo", "cto", "cfo", "adminteam", "management", "director",

        // Tech / Software brands
        "adobe", "photoshop", "illustrator", "figma",
        "notion", "jira", "confluence",

        // Gaming / Digital
        "steam", "epic", "playstation", "xbox", "sony",

        // Telecommunication
        "airtel", "orange",

        // Delivery & Transport
        "uber", "ubereats", "lyft", "grab", "gojek",

        // Insurance
        "aig", "prudential", "statefarm", "geico", "allstate", "allianz",

        // General restricted terms
        "info", "contact", "service", "services", "customer", "client",
        "team", "department", "office", "division", "center",
        "portal", "desk", "unit", "hq", "corporate", "supportteam",

        // Adult content
        "sex", "porn", "xxx", "nude", "boobs", "penis", "vagina", "fuck", "shit",
        "cock", "pussy", "erotic", "adult", "nsfw", "fetish", "milf", "dick"
    ]
}
