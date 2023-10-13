#!/bin/bash

# Fungsi untuk memeriksa keberadaan grup atau pengguna
check_existence() {
  if grep -q "$1" "$2"; then
    echo "Pass"
  else
    echo "Fail"
  fi
}

# Fungsi untuk memeriksa anggota grup
check_group_membership() {
  if id "$1" &>/dev/null; then
    groups=$(groups "$1")
    if [[ "$groups" == *"HCAI"* ]]; then
      echo "Pass"
    else
      echo "Fail"
    fi
  else
    echo "Belum dibuat"
  fi
}


# Fungsi untuk memeriksa direktori
check_directory() {
  if [ -d "$1" ]; then
    echo "Sudah dibuat"
    ownership=$(stat -c %G "$1")
    permissions=$(stat -c %a "$1")
    special_permission=$(stat -c %A "$1")
    if [ "$ownership" == "HCAI" ] && [ "$permissions" == "2770" ] && [ "$special_permission" == "drwxrws---" ]; then
      echo "7.Permision Pass"
    else
      echo "7.Permision Fail"
    fi
  else
    echo "Belum dibuat"
  fi
}

# Fungsi untuk memeriksa UID
check_uid() {
  user_uid=$(id -u "$1")
  if [ "$user_uid" == "$2" ]; then
    echo "Pass"
  else
    echo "Fail"
  fi
}

# Fungsi untuk memeriksa pengaturan kata sandi
check_password_settings() {
  password_expire_days=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}')
  umask_value=$(grep -E '^UMASK' /etc/login.defs | awk '{print $2}')
  if [ "$password_expire_days" == "2023" ] && [ "$umask_value" == "0000" ]; then
    echo "Pass"
  else
    echo "Fail"
  fi
}

# Mengecek keberadaan grup HCAI
echo "1. Grup HCAI: $(check_existence 'HCAI' /etc/group)"

# Mengecek pengguna Mentor
echo "2. Pengguna Mentor: $(check_group_membership 'Mentor')"
# Mengecek pengguna Senior
echo "3. Pengguna Senior: $(check_group_membership 'Senior')"
# Mengecek pengguna Digital
if id "Digital" &>/dev/null; then
  user_shell=$(getent passwd Digital | cut -d: -f7)
  if [ "$user_shell" == "/sbin/nologin" ]; then
    echo "4. Pengguna Digital: Pass"
  else
    echo "4. Pengguna Digital: Fail"
  fi
else
  echo "4. Pengguna Digital: Belum dibuat"
fi

# Mengecek keberadaan direktori /mentor/mentee
echo "5. Direktori /mentor/mentee: $(check_directory '/mentor/mentee')"

# Mengecek pengguna IbnuSaid
if id "IbnuSaid" &>/dev/null; then
  echo "6. Pengguna IbnuSaid: Pass"
else
  echo "6. Pengguna IbnuSaid: Belum dibuat"
fi

# Mengecek UID untuk pengguna IbnuSaid
echo "8. UID untuk pengguna IbnuSaid: $(check_uid 'IbnuSaid' '2023')"

# Mengecek apakah pengguna "Security" sudah dibuat
if id "Security" &>/dev/null; then
  echo "9. Pengguna 'Security': Pass"
else
  echo "9. Pengguna 'Security': Belum dibuat"
fi

# Mengecek masa berlaku kata sandi untuk pengguna "Security"
if id "Security" &>/dev/null; then
  password_max_days=$(chage -l Security | grep "Maximum number of days between password change" | awk -F: '{print $2}' | xargs)
  echo "10. Masa berlaku kata sandi untuk pengguna 'Security': $(check_uid 'Security' '2023')"
fi

# Mengecek izin untuk pengguna "Security"
if id "Security" &>/dev/null; then
  user_umask=$(umask)
  echo "11. Izin untuk pengguna 'Security': $(check_uid 'Security' '0000')"
fi

# Mengecek pengaturan Sudo Privilege
if grep -q "HCAI ALL=(ALL) NOPASSWD: ALL" /etc/sudoers || [ -f /etc/sudoers.d/HCAI ]; then
  echo "12. Sudo Privilege: Pass"
else
  echo "12. Sudo Privilege: Fail"
fi

# Mengecek konfigurasi SSH
sshd_config_file="/etc/ssh/sshd_config"
if grep -q "PasswordAuthentication no" "$sshd_config_file" && grep -q "PubkeyAuthentication yes" "$sshd_config_file"; then
  echo "13. Konfigurasi SSH: Pass"
else
  echo "13. Konfigurasi SSH: Fail"
fi
