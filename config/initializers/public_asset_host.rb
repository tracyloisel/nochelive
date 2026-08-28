require Rails.root.join("lib/public_asset_host")

Rails.application.config.middleware.use PublicAssetHost
