**16 · Platforms**

# Windows

> Flutter builds a Windows executable with one command. Turning that into something a person can install, upgrade and uninstall is an installer-authoring problem, and installer authoring has a specific failure mode: it succeeds while producing an empty package.

**Chunk prefix** win **Updated** 2026-08-01 **Depends on** 15 macOS

#### On this page

1. [Choosing a packaging format](#packaging)
1. [WiX authoring, and the version to pin](#wix)
1. [The absolute-path harvest trap](#harvest)
1. [The upgrade code is permanent](#upgradecode)
1. [Protocol handlers and deep links](#protocol)
1. [Code signing on Windows](#signing)
1. [CI from a Mac-based project](#ci)
1. [Platform differences that bite](#platform)

<!-- chunk: win.packaging | tags: windows,installer,distribution -->

## Choosing a packaging format

|   | MSI | MSIX | Zip |
| --- | --- | --- | --- |
| Install location | Per-machine or per-user | Per-user, containerised | Wherever the user unzips it |
| Upgrade in place | Yes, via the upgrade code | Yes | No |
| Add/Remove Programs | Yes | Yes | No |
| Registry writes | Yes — needed for protocol handlers | Restricted by the container | No |
| Microsoft Store | No | Yes | No |
| Authoring cost | Moderate — an XML document | Moderate | Zero |
| Enterprise deployment | Excellent | Good | Poor |

> **[RULE]**

> **Pick MSI for a direct-download desktop companion; pick MSIX only if you intend to publish to the Microsoft Store.** MSI gives per-machine installation, a real uninstall entry, and unrestricted registry access — which you need the moment you want a custom URL scheme to work. A zip is fine for an internal preview and unacceptable as a public download, because it has no uninstall story at all.

<!-- chunk: win.wix | tags: wix,msi,authoring -->

## WiX authoring, and the version to pin

WiX turns an XML document into an MSI. A minimal but complete document for a Flutter app is about forty lines.

```xml
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">
  <Package Name="MyApp" Manufacturer="Example"
           Version="$(var.ProductVersion)"
           UpgradeCode="CB5062A7-BF77-4543-B7F1-E88F3FF613F8"
           Scope="perMachine">

    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />
    <MediaTemplate EmbedCab="yes" />

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="INSTALLFOLDER" Name="MyApp" />
    </StandardDirectory>

    <!-- Harvest the whole publish directory. PublishDir MUST be absolute. -->
    <Files Include="$(var.PublishDir)\**">
      <Exclude Files="$(var.PublishDir)\**\*.pdb" />
    </Files>

    <StandardDirectory Id="ProgramMenuFolder">
      <Directory Id="AppMenuFolder" Name="MyApp">
        <Component Id="StartMenuShortcut" Guid="*">
          <Shortcut Id="AppShortcut" Name="MyApp"
                    Target="[INSTALLFOLDER]myapp.exe"
                    WorkingDirectory="INSTALLFOLDER" />
          <RemoveFolder Id="RemoveAppMenuFolder" On="uninstall" />
          <RegistryValue Root="HKCU" Key="Software\Example\MyApp"
                         Name="installed" Type="integer" Value="1" KeyPath="yes" />
        </Component>
      </Directory>
    </StandardDirectory>
  </Package>
</Wix>
```

```bash
wix build windows/installer/myapp.wxs \
  -arch x64 \
  -d ProductVersion=1.4.2 \
  -d PublishDir="$(pwd)/build/windows/x64/runner/Release" \
  -o "MyApp-1.4.2.msi"
```

> **[RULE]**

> **Pin the WiX major version.** One project pins to the 5.x line for two concrete reasons: version 7 and later require accepting an open-source maintenance-fee licence agreement, which fails an unattended CI build with a specific error code; and 5.x shares the v4/v5 authoring schema, so the document above does not need rewriting. Treat a WiX major bump as a migration task, not a routine update.

<!-- chunk: win.harvest | tags: wix,trap,build -->

## The absolute-path harvest trap

> **[TRAP]**

> **Symptom: the MSI builds successfully, installs successfully, and installs nothing. The file is a few kilobytes and contains a shortcut pointing at an executable that is not there.**

> **Cause:** WiX resolves a `<Files Include>` wildcard *relative to the `.wxs` document*, not relative to the working directory. A repo-relative `PublishDir` therefore points somewhere that does not exist — and an empty harvest is **not an error** to WiX. It builds a valid, empty package and exits zero.

> **Fix:** pass an absolute path, and then guard against the failure anyway, because the next person will hit it a different way:

> ```powershell
> $publish = Resolve-Path "build/windows/x64/runner/Release"
>
> # Guard 1 — the payload must exist before we build.
> if (-not (Test-Path "$publish\myapp.exe")) {
>   throw "myapp.exe missing from $publish — did `flutter build windows` run?"
> }
>
> wix build windows/installer/myapp.wxs -arch x64 `
>   -d ProductVersion=$version -d PublishDir=$publish -o $msi
>
> # Guard 2 — an MSI that small cannot contain an application.
> if ((Get-Item $msi).Length -lt 10MB) {
>   throw "MSI is $((Get-Item $msi).Length) bytes — the harvest was empty."
> }
> ```

> Both guards exist because in one project *every MSI built before the fix* was a 6 KB shortcut with no application in it, and nothing in the build output said so.

> **[WHY]**

> You could enumerate the MSI's file table and assert the executable is present, and that is strictly better. A size floor is one line, catches the same failure, and has never produced a false positive in practice. Start with the cheap guard; upgrade it if it ever fires spuriously.

<!-- chunk: win.upgradecode | tags: msi,upgrade,identity -->

## The upgrade code is permanent

> **[RULE]**

> **The `UpgradeCode` GUID is your product's permanent identity. Generate it once, commit it, and never change it.** Windows uses it to recognise that a new MSI supersedes an installed one. Change it and every future installer becomes, from the OS's point of view, a *different product* — it installs alongside the old one instead of replacing it, and users accumulate copies with no indication anything is wrong.

> Put a comment next to it in the document saying exactly this. It is a single GUID with no visible effect during development and catastrophic effect after release.

Version numbering rules that follow from how the installer compares versions:

| Rule | Detail |
| --- | --- |
| Only the first three fields are compared | `1.4.2.7` and `1.4.2.9` are the *same version* to the upgrade logic. Never encode a build number in the fourth field and expect an upgrade. |
| Each field has a maximum | Major and minor cap at 255; build caps at 65 535. A wall-clock build number will not fit — keep the MSI version as plain semver. |
| Version must increase | `MajorUpgrade` blocks downgrades with your message. Test that message once so you know users will understand it. |

> **[CHECK]**

> The only meaningful installer test: install version N, launch it, install version N+1 *without uninstalling*, and confirm one entry in Add/Remove Programs, the new version running, and user data preserved. Then uninstall and confirm nothing is left behind except intentionally-kept user data. Run this once per release; it takes five minutes and it is the entire risk surface.

<!-- chunk: win.protocol | tags: deep-links,registry,protocol-handler -->

## Protocol handlers and deep links

Custom URL schemes on Windows are registry entries the installer writes — which is one of the main reasons to prefer MSI over a container format.

```xml
<Component Id="ProtocolHandler" Guid="*" Directory="INSTALLFOLDER">
  <RegistryKey Root="HKLM" Key="Software\Classes\myapp">
    <RegistryValue Type="string" Value="URL:MyApp Protocol" />
    <RegistryValue Name="URL Protocol" Type="string" Value="" />
    <RegistryKey Key="shell\open\command">
      <RegistryValue Type="string" Value="&quot;[INSTALLFOLDER]myapp.exe&quot; &quot;%1&quot;" />
    </RegistryKey>
  </RegistryKey>
</Component>
```

This makes `myapp://…` launch the application with the URL as its first argument — which matters for [OAuth redirects](08-authentication.html#redirect), for QR payloads and for links from other applications.

> **[TRAP]**

> **Symptom: the first launch handles the URL and subsequent ones do not.** Windows starts a *new process* for each protocol activation. If your app is already running, the second process must detect the first, hand it the URL, and exit — otherwise you get two windows and the URL lands in the wrong one. Implement single-instance handling (a named mutex plus an IPC hand-off) at the same time as the protocol handler, not later.

> **[RULE]**

> **Quote the executable path and the argument in the registry value.** The default install path contains a space (`C:\Program Files\…`). An unquoted command splits on it, and the resulting error message names a directory rather than the real problem.

<!-- chunk: win.signing | tags: signing,smartscreen,certificates -->

## Code signing on Windows

Signing is optional in the sense that an unsigned MSI installs. It is not optional in the sense that users will run it.

|   | Unsigned | Standard certificate | Extended-validation certificate |
| --- | --- | --- | --- |
| SmartScreen on first download | Prominent warning; the run option is hidden behind "More info" | Warning until reputation accumulates | Trusted immediately |
| Cost | None | Annual | Higher annual, plus organisation validation |
| Key storage | — | Increasingly hardware-token-only | Hardware token |
| CI-friendly | — | Awkward — a token is physical; cloud signing services exist | Same |

> **[RULE]**

> **If you ship unsigned, say so on the download page and explain the warning.** A user who hits an unexplained SmartScreen block concludes the software is malicious — which is the intended behaviour of the warning. A one-paragraph note ("this build is not code-signed; click More info → Run anyway") converts an abandoned download into a completed one. This is the Windows form of [honest degradation](04-robustness.html#honest): do not pretend the artifact is something it is not.

Hardware-token requirements make signing genuinely awkward for a CI pipeline. If you need it, budget for a cloud signing service rather than assuming a certificate file can sit in a secret.

<!-- chunk: win.ci | tags: ci,github-actions,cross-platform -->

## CI from a Mac-based project

You do not need a Windows machine. A hosted Windows runner builds and packages, and the artifact comes back as a release asset.

```yaml
name: Windows MSI
on:
  workflow_dispatch:
    inputs: { ref: { description: 'Ref to build', default: 'master' } }
  pull_request:
    paths: ['windows/**', '.github/workflows/windows-msi.yml']
  push:
    tags: ['v*']

jobs:
  msi:
    runs-on: windows-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v7
        with: { ref: "${{ inputs.ref || github.ref }}" }

      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: "3.41.9" }

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build windows --release

      # Pinned major — v7+ requires accepting a licence agreement that
      # fails an unattended build.
      - run: dotnet tool install --global wix --version 5.0.2

      - name: Build the MSI (absolute PublishDir + both guards)
        shell: pwsh
        run: ./windows/installer/build.ps1 -Version "${{ steps.v.outputs.semver }}"

      - uses: actions/upload-artifact@v4
        with: { name: windows-msi, path: "*.msi" }

      - name: Attach to the release on a tag
        if: startsWith(github.ref, 'refs/tags/v')
        run: gh release upload "${GITHUB_REF#refs/tags/}" *.msi
        env: { GH_TOKEN: "${{ github.token }}" }
```

> **[RULE]**

> **Run the Windows build on pull requests that touch shared Dart code, even though you only distribute from tags.** A `dart:io` assumption, a path separator, or a plugin with no Windows implementation then fails in CI rather than at release time — when you are least able to absorb the delay. Build on PRs, package on tags.

<!-- chunk: win.platform | tags: windows,dart,platform-differences -->

## Platform differences that bite

| Area | Detail |
| --- | --- |
| **Path separators** | Always `path.join`. A hard-coded `/` works in many places on Windows and fails in exactly the ones that matter. |
| **Path length** | The classic 260-character limit still bites in deep build trees. Keep CI checkout paths short. |
| **Line endings** | Set `* text=auto` in `.gitattributes`, or generated-file diffs will differ per platform and your codegen-drift job will fail on Windows for no real reason. |
| **Case sensitivity** | The filesystem is case-insensitive. An import with the wrong case works on Windows and fails on Linux CI. |
| **Secure storage** | Backed by the Windows credential store; quotas and behaviour differ from the mobile keychains. Test it, do not assume. |
| **Window management** | Set a minimum window size in the native runner. The default is not usable. |
| **Plugin coverage** | Sparser than macOS. Check each plugin has a Windows implementation before promising the target; a missing one usually throws at runtime. |
| **Bluetooth / NFC / camera** | Assume unavailable and hide those surfaces. See [three-state availability](12-nfc-rfid.html#status). |

> **[TRAP]**

> **Symptom: the codegen-drift CI job fails only on the Windows runner.** Line-ending normalisation. Generated files written on Windows carry `\r\n`, the committed versions carry `\n`, and every generated file appears modified. Fix it in `.gitattributes` before adding a Windows job, not after.

#### Sources for this page

- One project's Windows MSI workflow and its WiX v5 authoring: the pinned tool version with the licence-agreement rationale, the absolute-`PublishDir` requirement discovered after every earlier MSI shipped empty, the two guards (missing executable, undersized MSI), the permanent upgrade-code GUID, and the per-machine install with a Start-menu shortcut and a protocol-handler registration.

The signing comparison, the single-instance protocol trap and the platform-differences table are general Windows knowledge rather than observations from that project's code.
