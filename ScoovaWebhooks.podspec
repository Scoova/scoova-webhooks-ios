Pod::Spec.new do |s|
  s.name             = 'ScoovaWebhooks'
  s.version          = '1.0.1'
  s.summary          = 'Webhook subscription CRUD plus HMAC-SHA256 signature verification.'

  s.description      = <<-DESC
    Webhook subscription CRUD plus HMAC-SHA256 signature verification.

    Pure Swift. Uses URLSession + async/await. Auto-detects
    `Bundle.main.bundleIdentifier` for the X-Ios-Bundle-Identifier
    key-restriction header. Locale-aware (`Accept-Language` + `?locale=`,
    default `en`).
  DESC

  s.homepage         = 'https://cloud.scoo-va.info'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'Scoova' => 'info@scoo-va.info' }
  s.source           = { :git => 'https://github.com/Scoova/scoova-webhooks-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target     = '15.0'
  s.osx.deployment_target     = '12.0'

  s.swift_versions   = ['5.9']
  s.source_files     = 'Sources/ScoovaWebhooks/**/*.swift'
end
