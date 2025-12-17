component 'openssl' do |pkg, settings, platform|
  pkg.version '3.0.18'
  pkg.sha256sum 'd80c34f5cf902dccf1f1b5df5ebb86d0392e37049e5d73df1b3abae72e4ffe8b'

  pkg.url "https://openssl.org/source/openssl-#{pkg.get_version}.tar.gz"

  #############
  # ENVIRONMENT
  #############

  # OpenSSL 3 accepts CFLAGS, etc environment variables (unlike 1.1.1)

  if platform.is_el? && platform.is_fips?
    pkg.build_requires 'perl-core'

    pkg.environment 'PATH', '$(PATH):/usr/local/bin'

    target = 'linux-x86_64'
  elsif platform.is_windows?
    pkg.build_requires 'strawberryperl'

    pkg.environment 'PATH', "$(shell cygpath -u #{settings[:gcc_bindir]}):$(PATH)"

    target = 'mingw64'
  else
    raise 'The openssl-fips component is only supported on RHEL and Windows'
  end

  pkg.environment 'CFLAGS', settings[:cflags]
  pkg.environment 'LDFLAGS', settings[:ldflags]

  ###########
  # CONFIGURE
  ###########

  configure_flags = [
    "--prefix=#{settings[:prefix]}",
    '--libdir=lib',
    "--openssldir=#{settings[:ssldir]}",
    'shared',
    target,
    'enable-fips'
  ]

  pkg.configure do
    ["./Configure #{configure_flags.join(' ')}"]
  end

  #######
  # BUILD
  #######

  pkg.build do
    [
      platform[:make]
    ]
  end

  #########
  # INSTALL
  #########

  pkg.install do
    [
      "#{platform[:make]} #{settings[:install_prefix]} install_fips",
      "rm #{settings[:fipsmodule_cnf]}"
    ]
  end
end
