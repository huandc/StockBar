cask "stockbar" do
  version "1.0.0"
  sha256 "aea6f7283daed579a65ed9dd35adaf96aa1c589768af64244da573cc0e5a9eaf"

  url "https://github.com/huandc/StockBar/releases/download/v#{version}/StockBar-#{version}-macOS.zip"
  name "StockBar"
  desc "Menu bar stock ticker for Yahoo Finance and EastMoney"
  homepage "https://github.com/huandc/StockBar"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "StockBar.app"

  zap trash: [
    "~/Library/Preferences/com.huandc.StockBar.plist",
    "~/Library/Saved Application State/com.huandc.StockBar.savedState",
  ]

  caveats <<~EOS
    StockBar 未做 Apple 公证,首次启动请右键 App →「打开」确认一次,
    或在「系统设置 → 隐私与安全性」里点「仍要打开」。
  EOS
end
