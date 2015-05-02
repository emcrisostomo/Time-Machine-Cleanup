install:
	[[ -x ./install.sh ]] || chmod +x ./install.sh
	./install.sh

uninstall:
	[[ -x ./uninstall.sh ]] || chmod +x ./uninstall.sh
	./uninstall.sh
