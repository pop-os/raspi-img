ARCH=arm64
UBUNTU_CODE=impish
UBUNTU_MIRROR=http://ports.ubuntu.com/ubuntu-ports

BUILD=build/$(UBUNTU_CODE)

all: $(BUILD)/raspi.zip

clean:
	# Remove image file
	#TODO: remove partial image file (after ensuring it is not in use)
	sudo rm -f "$(BUILD)/raspi.img"

	# Remove zip file
	rm -f "$(BUILD)/raspi.zip" "$(BUILD)/raspi.zip.partial"

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
	if [ ! -f /usr/bin/zip ]; then \
		sudo apt-get install --yes zip; \
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
	# Create image
	sudo data/image.sh "$@.partial" "$(BUILD)/mount" "$<"

	# Mark as complete
	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

#TODO: should we use xz or something?
$(BUILD)/raspi.zip: $(BUILD)/raspi.img
	# Make zip file
	zip -j "$@.partial" "$<"

	# Mark as complete
	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"
