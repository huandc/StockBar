cask "stockbar" do
  version "1.1.0"
  sha256 "f6add5a96a805f97423c6423d3d99d272bb1ea5ab142b983d572a33487f0713c"

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
