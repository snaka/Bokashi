# Releasing Bokashi

The release pipeline lives in [`.github/workflows/release.yml`](.github/workflows/release.yml).
It signs, notarizes, packages, publishes a GitHub Release, and bumps the
[`snaka/homebrew-tap`](https://github.com/snaka/homebrew-tap) formula.

## One-time setup

### 1. Apple Developer assets

You'll need:

- A **Developer ID Application** certificate (from Apple Developer Account → Certificates).
  Export it as a `.p12` from Keychain Access (right-click → Export). Set a strong password.
- Your **Team ID** (10-char string, visible in [Account → Membership](https://developer.apple.com/account/#MembershipDetailsCard)).
- An **app-specific password** for `notarytool`. Generate one at
  [appleid.apple.com → Sign-in and Security → App-Specific Passwords](https://appleid.apple.com).
  Label it e.g. `bokashi-notarytool`.

### 2. GitHub PAT for the tap

Create a **fine-grained personal access token** restricted to the
`snaka/homebrew-tap` repository, with `Contents: Read and write`. Save it
somewhere temporarily.

### 3. Add repository secrets to `snaka/Bokashi`

`Settings → Secrets and variables → Actions → New repository secret`:

| Secret | Value |
|---|---|
| `DEVELOPER_ID_CERT_P12_BASE64` | `base64 -i cert.p12 \| pbcopy` and paste |
| `DEVELOPER_ID_CERT_PASSWORD` | The .p12 export password |
| `KEYCHAIN_PASSWORD` | Any random string (e.g. `openssl rand -hex 32`); only used for the temp keychain |
| `AC_USERNAME` | Your Apple ID email |
| `AC_PASSWORD` | The app-specific password from step 1 |
| `AC_TEAM_ID` | Your 10-char Team ID |
| `TAP_PUSH_TOKEN` | The fine-grained PAT from step 2 |
| `SPARKLE_ED_PRIVATE_KEY` | Sparkle EdDSA private key (see "Sparkle auto-update one-time setup" below) |

### 4. Sparkle auto-update one-time setup

Required once before the first release that ships Sparkle (v0.6.0+).
If `SPARKLE_ED_PRIVATE_KEY` is missing, releases still build and ship,
but no appcast entry is written and auto-update clients won't see the
new version.

1. **Locate Sparkle's CLI tools**. They ship with the Sparkle SPM
   package and are unpacked into Xcode's DerivedData the first time
   Bokashi is built. Find them with:
   ```bash
   SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData \
     -path '*/artifacts/sparkle/Sparkle/bin' -type d 2>/dev/null | head -1)
   echo "$SPARKLE_BIN"
   ```
   If empty, run a Debug build of Bokashi once (`xcodebuild build`),
   then re-run the find.
2. **Generate the EdDSA key pair**:
   ```bash
   "$SPARKLE_BIN/generate_keys"
   ```
   This stores the **private key in your login keychain** under
   "https://sparkle-project.org" and prints the **public key** to
   stdout (a base64 string like `MCowB...`).
3. **Put the public key in `project.yml`**: replace the empty
   `SUPublicEDKey: ""` with the printed value, then `xcodegen` and
   commit. (Yes, the public key lives in the repo — that is the whole
   point of asymmetric signing.)
4. **Export the private key**:
   ```bash
   "$SPARKLE_BIN/generate_keys" -x sparkle_priv.key
   ```
   Add the contents of `sparkle_priv.key` as the
   `SPARKLE_ED_PRIVATE_KEY` repository secret, then **delete the
   file** locally. Losing the key is annoying but recoverable: you
   can rotate by generating a new pair and re-publishing the public
   key in a new app version. Without the private key, you can never
   ship updates that existing installs will accept.
5. **Enable GitHub Pages on the repo**:
   `Settings → Pages → Source: Deploy from a branch → Branch: main →
   Folder: /docs → Save`. After the first release pushes a real entry
   into `docs/appcast.xml`, the feed will be available at
   <https://snaka.github.io/Bokashi/appcast.xml>.

## Cutting a release

### Dry-run (recommended for first run)

Use the **Run workflow** button on the Actions tab → Release → fill in a version like `0.4.0-dryrun`. This will:

- Build, sign, notarize, and create a `.dmg`.
- Upload it as a workflow **artifact** (downloadable from the run page).
- **Skip** GitHub Release creation and tap formula update.

Use this to validate signing/notarization without polluting Releases or the tap.

### Real release

```bash
# from the Bokashi repo
git tag v0.4.0
git push origin v0.4.0
```

The workflow will:

1. Resolve version from the tag (`v0.4.0` → `0.4.0`).
2. Build a Release-configuration archive with `MARKETING_VERSION=0.4.0`.
3. Sign with Developer ID and notarize the `.app`.
4. Build a `.dmg`, notarize and staple it.
5. Create a GitHub Release with auto-generated notes, attach the `.dmg`.
6. Push an updated `Casks/bokashi.rb` to `snaka/homebrew-tap`.

After it succeeds, `brew install --cask snaka/tap/bokashi` should work.

## Troubleshooting

- **`security: SecKeychainItemImport: error -25257`** — the .p12 password in `DEVELOPER_ID_CERT_PASSWORD` is wrong.
- **`No identity found`** — the certificate didn't import cleanly. Verify the .p12 actually contains both the cert and the private key (Keychain Access export should produce both by default).
- **Notarization rejected** — view detail with:
  ```bash
  xcrun notarytool log <submission-id> \
    --apple-id "$AC_USERNAME" --password "$AC_PASSWORD" --team-id "$AC_TEAM_ID"
  ```
  Common cause: missing hardened runtime entitlement, or signing with a non-Developer-ID identity.
- **Tap push fails with 403** — the PAT scope is wrong; make sure it has `Contents: Read and write` for `snaka/homebrew-tap`.

## Future migrations

- **App Store Connect API key** can replace `AC_USERNAME`/`AC_PASSWORD` for `notarytool` (more robust). Swap to `--key`, `--key-id`, `--issuer` once the project is mature.
- **Submit to official `homebrew/cask`** when the project hits v1.0 with stable release cadence.
