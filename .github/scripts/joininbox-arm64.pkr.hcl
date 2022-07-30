
source "arm" "autogenerated" {
  file_checksum_type    = "sha256"
  file_checksum_url     = "https://raspi.debian.net/tested/20220121_raspi_4_bullseye.img.xz.sha256"
  file_target_extension = "xz"
  file_unarchive_cmd    = ["xz", "--decompress", "$ARCHIVE_PATH"]
  file_urls             = ["https://raspi.debian.net/tested/20220121_raspi_4_bullseye.img.xz"]
  image_build_method    = "resize"
  image_chroot_env      = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "8192"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "532480"
    type         = "83"
  }
  image_path                   = "joininbox-arm64.img"
  image_size                   = "8G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
}

build {
  sources = ["source.arm.autogenerated"]

  provisioner "file" {
    destination = "/tmp"
    source      = "scripts/resizerootfs"
  }

  provisioner "shell" {
    script = "scripts/bootstrap_resizerootfs.sh"
  }

  provisioner "file" {
    destination = "/tmp/packages.config"
    source      = "packages.config"
  }

  provisioner "shell" {
    inline = ["echo set debconf to Noninteractive", "echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections"]
  }

  provisioner "shell" {
    inline = ["echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' | tee -a /etc/resolv.conf", "apt-get update -y", "apt-get upgrade -y", "apt-get install $(cat /tmp/packages.config) -y"]
  }

  provisioner "shell" {
    script = "build_joininbox.sh"
  }

  post-processor "compress" {
    compression_level = 9
    output            = "{{.BuildName}}_{{.BuilderType}}.tar.gz"
  }

  post-processor "checksum" { # checksum image
    checksum_types      = ["sha256"]
    output              = "{{.BuildName}}_{{.BuilderType}}.tar.gz{{.ChecksumType}}"
    keep_input_artifact = true
  }
}
