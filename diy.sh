#!/bin/bash
svn_export() {
	# 参数1是分支名, 参数2是子目录, 参数3是目标目录, 参数4仓库地址
	TMP_DIR="$(mktemp -d)" || exit 1
 	ORI_DIR="$PWD"
	[ -d "$3" ] || mkdir -p "$3"
	TGT_DIR="$(cd "$3"; pwd)"
	git clone --depth 1 -b "$1" "$4" "$TMP_DIR" >/dev/null 2>&1 && \
	cd "$TMP_DIR/$2" && rm -rf .git >/dev/null 2>&1 && \
	cp -af . "$TGT_DIR/" && cd "$ORI_DIR"
	rm -rf "$TMP_DIR"
}
#cp -f $GITHUB_WORKSPACE/patch/mt7621_xiaomi_mi-router-3g.dts target/linux/ramips/dts/mt7621_xiaomi_mi-router-3g.dts
#cp -f $GITHUB_WORKSPACE/patch/02_network target/linux/ramips/mt7621/base-files/etc/board.d/02_network
cp -f $GITHUB_WORKSPACE/patch/102-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.4/102-mt7621-fix-cpu-clk-add-clkdev.patch
cp -f $GITHUB_WORKSPACE/patch/322-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.10/322-mt7621-fix-cpu-clk-add-clkdev.patch

cp -f $GITHUB_WORKSPACE/patch/mt7621_fw40.dtsi target/linux/ramips/dts/mt7621_fw40.dtsi
cp -f $GITHUB_WORKSPACE/patch/mt7621_fw40.dts target/linux/ramips/dts/mt7621_fw40.dts
#写入make
echo '

define Device/fw40
  $(Device/dsa-migration)
  $(Device/uimage-lzma-loader)
  IMAGE_SIZE := 32448k
  DEVICE_VENDOR := Doonink
  DEVICE_MODEL := FW40
  DEVICE_VARIANT := 32M
  DEVICE_PACKAGES := mod-usb-ledtrig-usbport\
		kmod-mt7603 kmod-mt76x2 \
		kmod-usb3
  SUPPORTED_DEVICES +=fw40 doonink,fw40
endef
TARGET_DEVICES += fw40

' >> target/linux/ramips/image/mt7621.mk

# 删除冲突软件和依赖
rm -rf feeds/packages/lang/golang 
rm -rf feeds/luci/applications/luci-app-filebrowser
rm -rf feeds/luci/applications/luci-app-pushbot
rm -rf feeds/luci/applications/luci-app-serverchan
rm -rf feeds/luci/applications/luci-app-adguardhome
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-zerotier
rm -rf feeds/luci/applications/luci-app-alist
rm -rf feeds/packages/net/alist
rm -rf feeds/packages/net/zerotier
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-design/root/etc/uci-defaults/30_luci-theme-design
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f
git clone --depth 1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
# 下载插件
git clone --depth 1 https://github.com/fw876/helloworld package/helloworld
git clone --depth 1 https://github.com/sbwml/luci-app-alist package/luci-app-alist
git clone --depth 1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth 1 https://github.com/chenmozhijin/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth 1 https://github.com/tty228/luci-app-wechatpush package/luci-app-wechatpush
git clone --depth 1 https://github.com/OldCoding/luci-app-filebrowser package/luci-app-filebrowser
svn_export "master" "applications/luci-app-smartdns" "feeds/luci/applications/luci-app-smartdns" "https://bgithub.xyz/immortalwrt/luci"
svn_export "master" "net/smartdns" "feeds/packages/net/smartdns" "https://bgithub.xyz/immortalwrt/packages"
svn_export "main" "luci-app-passwall" "package/luci-app-passwall" "https://bgithub.xyz/xiaorouji/openwrt-passwall"
svn_export "master" "applications/luci-app-zerotier" "feeds/luci/applications/luci-app-zerotier" "https://bgithub.xyz/immortalwrt/luci"
svn_export "master" "net/zerotier" "feeds/packages/net/zerotier" "https://bgithub.xyz/immortalwrt/packages"
svn_export "v5" "luci-app-mosdns" "package/luci-app-mosdns" "https://bgithub.xyz/sbwml/luci-app-mosdns"
svn_export "v5" "mosdns" "package/mosdns" "https://bgithub.xyz/sbwml/luci-app-mosdns"
svn_export "v5" "v2dat" "package/v2dat" "https://bgithub.xyz/sbwml/luci-app-mosdns"
svn_export "main" "easytier" "package/easytier" "https://bgithub.xyz/EasyTier/luci-app-easytier"
svn_export "main" "luci-app-easytier" "package/luci-app-easytier" "https://bgithub.xyz/EasyTier/luci-app-easytier"

# 编译 po2lmo (如果有po2lmo可跳过)
#pushd package/luci-app-openclash/tools/po2lmo
#make && sudo make install
#popd

# 安装插件
./scripts/feeds update -i
./scripts/feeds install -a

# 调整菜单位置
sed -i "s|services|system|g" feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i "s|services|network|g" feeds/luci/applications/luci-app-nlbwmon/root/usr/share/luci/menu.d/luci-app-nlbwmon.json

# 个性化设置
cd package
sed -i "s/LEDE /Wing build $(TZ=UTC-8 date "+%Y.%m.%d") @ LEDE /g" lean/default-settings/files/zzz-default-settings
sed -i "s/LEDE/MI-R3G/" base-files/luci2/bin/config_generate
sed -i "/ntp/d" lean/default-settings/files/zzz-default-settings
sed -i "/firewall\.user/d" lean/default-settings/files/zzz-default-settings
sed -i "s/192.168.1.1/192.168.10.1/g" base-files/luci2/bin/config_generate
sed -i "/openwrt_luci/d" lean/default-settings/files/zzz-default-settings
sed -i "s/encryption='.*'/encryption='sae-mixed'/g" kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i "s/country='.*'/country='CN'/g" kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i '186i \\t\t\tset wireless.default_radio${devidx}.key=123456789' kernel/mac80211/files/lib/wifi/mac80211.sh

# 更新passwall规则
curl -sfL -o ./luci-app-passwall/root/usr/share/passwall/rules/gfwlist https://raw.bgithub.xyz/Loyalsoldier/v2ray-rules-dat/release/gfw.txt
#AdguardHome
cd ./luci-app-adguardhome/root/usr
mkdir -p ./bin/AdGuardHome && cd ./bin/AdGuardHome
ADG_VER=$(curl -sfL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases 2>/dev/null | grep 'tag_name' | egrep -o "v[0-9].+[0-9.]" | awk 'NR==1')
curl -sfL -o /tmp/AdGuardHome_linux.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADG_VER}/AdGuardHome_linux_mipsle_softfloat.tar.gz
tar -zxf /tmp/*.tar.gz -C /tmp/ && chmod +x /tmp/AdGuardHome/AdGuardHome
#upx_latest_ver="$(curl -sfL https://api.github.com/repos/upx/upx/releases/latest 2>/dev/null | egrep 'tag_name' | egrep '[0-9.]+' -o 2>/dev/null)"
curl -sfL -o /tmp/upx-4.2.4-amd64_linux.tar.xz "https://bgithub.xyz/upx/upx/releases/download/v4.2.4/upx-4.2.4-amd64_linux.tar.xz"
xz -d -c /tmp/upx-4.2.4-amd64_linux.tar.xz | tar -x -C "/tmp"
/tmp/upx-4.2.4-amd64_linux/upx --ultra-brute /tmp/AdGuardHome/AdGuardHome > /dev/null 2>&1
mv /tmp/AdGuardHome/AdGuardHome ./ && rm -rf /tmp/AdGuardHome
#cd $GITHUB_WORKSPACE/openwrt && cd feeds/luci/applications/luci-app-wrtbwmon
#sed -i 's/ selected=\"selected\"//g' ./luasrc/view/wrtbwmon/wrtbwmon.htm && sed -i 's/\"1\"/\"1\" selected=\"selected\"/g' ./luasrc/view/wrtbwmon/wrtbwmon.htm
#sed -i 's/interval: 5/interval: 1/g' ./htdocs/luci-static/wrtbwmon/wrtbwmon.js

#添加qmodem
git clone --depth=1 -b main https://github.com/FUjr/QModem package/modem
echo "
CONFIG_PACKAGE_luci-i18n-qmodem-zh-cn=y
CONFIG_PACKAGE_luci-app-qmodem=y
CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan=y
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan is not set
CONFIG_PACKAGE_luci-app-qmodem_USE_TOM_CUSTOMIZED_QUECTEL_CM=y
# CONFIG_PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G is not set
# CONFIG_PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM is not set
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_PCI_SUPPORT is not set
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_QFIREHOSE_SUPPORT is not set
CONFIG_PACKAGE_luci-app-qmodem-hc=y
CONFIG_PACKAGE_luci-app-qmodem-mwan=y
CONFIG_PACKAGE_luci-app-qmodem-sms=y
CONFIG_PACKAGE_luci-app-qmodem-ttl=y
" >> .config 
