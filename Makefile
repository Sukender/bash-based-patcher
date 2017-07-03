# TODO:
#   Install README and COPYING
#   Install config file elsewhere (share?)
#   "INSTALL_PATH" should be configurable

INSTALL_PATH=/usr/local/bin

all:

install: all
	cp bbp $(INSTALL_PATH)
	cp bbpdiff $(INSTALL_PATH)
	cp bbppatch $(INSTALL_PATH)
	cp bbpar $(INSTALL_PATH)
	cp bbpinfo $(INSTALL_PATH)
	cp bbp_config.sh $(INSTALL_PATH)

uninstall:
	-rm -f $(INSTALL_PATH)/bbp
	-rm -f $(INSTALL_PATH)/bbpdiff
	-rm -f $(INSTALL_PATH)/bbppatch
	-rm -f $(INSTALL_PATH)/bbpar
	-rm -f $(INSTALL_PATH)/bbinfo
	-rm -f $(INSTALL_PATH)/bbp_config.sh

clean:
	-rm -r _diff_unit_test
	-rm -f patch.xz delta.patch

# Unit test should not be deployed actually, but as the tool is rather new and fragile, it may be useful
# For now, installation happens with Makefile, hence the inclusion of it in the package
package: all
	-rm -f "$$toolName.tar.xz"
	source "./bbp_config.sh" && tar -Jcf "$$toolName.tar.xz" bbp bbpdiff bbppatch bbpar bbpinfo bbp_config.sh bbp_unit_test.sh COPYING.txt README.md Makefile

test: all
	./bbp_unit_test.sh
