ARCH=arm64
UBUNTU_CODE?=noble
UBUNTU_MIRROR?=http://ports.ubuntu.com/ubuntu-ports

BUILD=build/$(UBUNTU_CODE)

SED=\
	s|UBUNTU_CODE|$(UBUNTU_CODE)|g; \
	s|UBUNTU_MIRROR|$(UBUNTU_MIRROR)|g

all: $(BUILD)/raspi.img.xz

clean:
	# Remove image file
	#TODO: remove partial image file (after ensuring it is not in use)
	sudo rm -f "$(BUILD)/raspi.img"

	# Remove compressed file
	rm -f "$(BUILD)/raspi.img.xz" "$(BUILD)/raspi.img.xz.partial"; \
	if [ "$$?" -ne "0" ]; then \
		mv "$(BUILD)" "/tmp/$(BUILD)-to-be-deleted"; \
	fi

distclean: clean
	# Remove debootstrap directory
	sudo rm -rf --one-file-system "$(BUILD)/debootstrap" "$(BUILD)/debootstrap.partial"

deps:
	if [ ! -f /usr/sbin/debootstrap ]; then \
		sudo apt-get install --yes debootstrap; \
	fi
	if [ ! -f /usr/bin/systemd-nspawn ]; then \
		sudo apt-get install --yes systemd-container; \
	fi
	if [ ! -f /usr/bin/pixz ]; then \
		sudo apt-get install --yes pixz; \
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

	# Mark as complete
	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/raspi.img: $(BUILD)/debootstrap
	# Generate templates
	rm -rf "data/etc/apt/sources.list.d"
	mkdir -p "data/etc/apt/sources.list.d"
	sed "$(SED)" "data/template/pop-os-release.sources" > "data/etc/apt/sources.list.d/pop-os-release.sources"
	sed "$(SED)" "data/template/system.sources" > "data/etc/apt/sources.list.d/system.sources"

	# Create image
	sudo data/image.sh "$@.partial" "$(BUILD)/mount" "$<" "$(UBUNTU_CODE)" "$(UBUNTU_MIRROR)"

	# Mark as complete
	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/raspi.img.xz: $(BUILD)/raspi.img
	# Make compressed file
	pixz -9 -t "$<" "$@.partial"

	# Mark as complete
	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"
