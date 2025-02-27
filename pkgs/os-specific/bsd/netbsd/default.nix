{
  lib,
  stdenvNoCC,
  makeScopeWithSplicing',
  generateSplicesForMkScope,
  buildPackages,
  fetchcvs,
}:

makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "netbsd";
  f = (
    self:
    lib.packagesFromDirectoryRecursive {
      callPackage = self.callPackage;
      directory = ./pkgs;
    }
    // {
      version = "9.2";

      defaultMakeFlags = [
        "MKSOFTFLOAT=${
          if
            stdenvNoCC.hostPlatform.gcc.float or (stdenvNoCC.hostPlatform.parsed.abi.float or "hard") == "soft"
          then
            "yes"
          else
            "no"
        }"
      ];

      compatIfNeeded = lib.optional (!stdenvNoCC.hostPlatform.isNetBSD) self.compat;

      # The manual callPackages below should in principle be unnecessary because
      # they're just selecting arguments that would be selected anyway. However,
      # if we don't perform these manual calls, we get infinite recursion issues
      # because of the splices.

      mkDerivation = self.callPackage ./pkgs/mkDerivation.nix {
        inherit (buildPackages.netbsd)
          netbsdSetupHook
          makeMinimal
          install
          tsort
          lorder
          ;
        inherit (buildPackages) mandoc;
        inherit (buildPackages.buildPackages) rsync;
      };

      makeMinimal = self.callPackage ./pkgs/makeMinimal.nix { inherit (self) make; };

      compat = self.callPackage ./pkgs/compat/package.nix {
        inherit (buildPackages) coreutils;
        inherit (buildPackages.darwin) cctools-port;
        inherit (buildPackages.buildPackages) rsync;
        inherit (buildPackages.netbsd) makeMinimal;
        inherit (self) install;
      };

      install = self.callPackage ./pkgs/install/package.nix {
        inherit (self)
          fts
          mtree
          make
          compatIfNeeded
          ;
        inherit (buildPackages.buildPackages) rsync;
        inherit (buildPackages.netbsd) makeMinimal;
      };

      # See note in pkgs/stat/package.nix
      stat = self.callPackage ./pkgs/stat/package.nix {
        inherit (buildPackages.netbsd) makeMinimal install;
        inherit (buildPackages.buildPackages) rsync;
      };

      # See note in pkgs/stat/hook.nix
      statHook = self.callPackage ./pkgs/stat/hook.nix { inherit (self) stat; };

      tsort = self.callPackage ./pkgs/tsort.nix {
        inherit (buildPackages.netbsd) makeMinimal install;
        inherit (buildPackages.buildPackages) rsync;
      };

      lorder = self.callPackage ./pkgs/lorder.nix {
        inherit (buildPackages.netbsd) makeMinimal install;
        inherit (buildPackages.buildPackages) rsync;
      };

      config = self.callPackage ./pkgs/config.nix {
        inherit (buildPackages.netbsd) makeMinimal install;
        inherit (buildPackages.buildPackages) rsync;
        inherit (self) cksum;
      };

      include = self.callPackage ./pkgs/include.nix {
        inherit (buildPackages.netbsd)
          makeMinimal
          install
          nbperf
          rpcgen
          ;
        inherit (buildPackages) stdenv;
        inherit (buildPackages.buildPackages) rsync;
      };

      sys-headers = self.callPackage ./pkgs/sys/headers.nix {
        inherit (buildPackages.netbsd)
          makeMinimal
          install
          tsort
          lorder
          statHook
          uudecode
          config
          genassym
          ;
        inherit (buildPackages.buildPackages) rsync;
      };

      libutil = self.callPackage ./pkgs/libutil.nix { inherit (self) libc sys; };

      libpthread-headers = self.callPackage ./pkgs/libpthread/headers.nix { };

      csu = self.callPackage ./pkgs/csu.nix {
        inherit (self) headers sys-headers ld_elf_so;
        inherit (buildPackages.netbsd)
          netbsdSetupHook
          makeMinimal
          install
          genassym
          gencat
          lorder
          tsort
          statHook
          ;
        inherit (buildPackages.buildPackages) rsync;
      };

      _mainLibcExtraPaths = [
        "common"
        "lib/i18n_module"
        "lib/libcrypt"
        "lib/libm"
        "lib/libpthread"
        "lib/libresolv"
        "lib/librpcsvc"
        "lib/librt"
        "lib/libutil"
        "libexec/ld.elf_so"
        "sys"
      ];

      libc = self.callPackage ./pkgs/libc.nix {
        inherit (self) headers csu librt;
        inherit (buildPackages.netbsd)
          netbsdSetupHook
          makeMinimal
          install
          genassym
          gencat
          lorder
          tsort
          statHook
          rpcgen
          ;
        inherit (buildPackages.buildPackages) rsync;
      };

      mtree = self.callPackage ./pkgs/mtree.nix { inherit (self) mknod; };
    }
  );
}
