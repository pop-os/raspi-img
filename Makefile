ARCH=arm64
UBUNTU_CODE=impish
UBUNTU_MIRROR=http://ports.ubuntu.com/ubuntu-ports

BUILD=build/$(UBUNTU_CODE)

all: $(BUILD)/chroot

distclean:
	# Remove debootstrap directory
	sudo rm -rf --one-file-system "$(BUILD)/debootstrap" "$(BUILD)/debootstrap.partial"

clean:
	# Remove chroot directory
	sudo rm -rf --one-file-system "$(BUILD)/chroot" "$(BUILD)/chroot.partial"

deps:
	if [ ! -f /usr/bin/systemd-nspawn ]; then \
		sudo apt-get install --yes systemd-container; \
	fi
	if [ ! -f /usr/sbin/debootstrap ]; then \
		sudo apt-get install --yes debootstrap; \
	fi

$(BUILD)/debootstrap:
	mkdir -p "$(BUILD)"

	# Remove old debootstrap
	sudo rm -rf --one-file-system "$@" "$@.partial"

	# Install using debootstrap
	if ! sudo debootstrap \
		"--arch=$(ARCH)" \
		"$(UBUNTU_CODE)" \
		"$@.partial" \
		"$(UBUNTU_MIRROR)"; \
	then \
		cat "$@.partial/debootstrap/debootstrap.log"; \
		false; \
	fi

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/chroot: $(BUILD)/debootstrap
	# Remove old chroot
	sudo rm -rf --one-file-system "$@" "$@.partial"

	# Copy debootstrap
	sudo cp --archive "$<" "$@.partial"

	# Set default sources
	sudo cp -v data/apt/sources.list "$@.partial/etc/apt/sources.list"
	sudo cp -v data/apt/sources.list.d/pop-os-ppa.list "$@.partial/etc/apt/sources.list.d/pop-os-ppa.list"
	sudo cp -v data/apt/sources.list.d/system.sources "$@.partial/etc/apt/sources.list.d/system.sources"
	sudo cp -v data/apt/trusted.gpg.d/pop-os-ppa.gpg "$@.partial/etc/apt/trusted.gpg.d/pop-os-ppa.gpg"

	# Copy override preferences
	#TODO sudo cp -v data/apt/preferences.d/pop-raspi-img "$@.partial/etc/apt/preferences.d/pop-raspi-img"

	# Copy setup script
	sudo cp -v "data/setup.sh" "$@.partial/setup.sh"

	# Launch container
	sudo systemd-nspawn \
		--machine=pop-os \
		--resolv-conf=off \
		--directory="$@.partial" \
		bash /setup.sh

	# Remove setup script
	sudo rm -v "$@.partial/setup.sh"

	# Remove override preferences
	#TODO sudo rm -v "$@.partial/etc/apt/preferences.d/pop-raspi-img"

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"
