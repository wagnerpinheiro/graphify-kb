# Reference: Sync a Teams channel / SharePoint library to your computer with OneDrive (for use by a local tool such as Claude Code)

Purpose: guide a user to make a shared workspace folder (Teams channel files = a SharePoint document library or folder) available as a normal local folder via the OneDrive sync app, so a local tool can read and write files in it.

Convention: everything without a marker is stated by Microsoft in the sources listed in section 6 (quotes are verbatim). Anything marked **(inference)** is not stated by Microsoft and is reasoning or common observed behavior; the skill should verify it on the user's machine.

Background facts (Microsoft):
- "Files you upload to a channel are stored in your team's SharePoint folder. These files are available in the Shared tab at the top of each channel." (Teams desktop; mobile still says "Files".)
- The main article applies to orgs with "a Microsoft 365 work or school subscription or uses SharePoint Server 2019 and Teams".
- Support for the old OneDrive for Business sync app (Groove.exe) with SharePoint Online has ended. The instructions below assume the current OneDrive sync app.

---

## 1. Two methods: "Add shortcut to My files" vs the "Sync" button

### What Microsoft says (main article, verbatim)

> "You have two options when syncing files in SharePoint libraries and Teams. You can either add shortcuts to libraries and folders to OneDrive or use the Sync button in the document library."
>
> "Both options allow essentially the same thing—users can access files on their local computer in Explorer or Finder. However, adding OneDrive shortcuts allows content to be accessed on all devices, whereas sync is related to a specific device. Additionally, OneDrive shortcuts offer improved performance versus using the sync button."
>
> "We recommend using OneDrive shortcuts as the more versatile option when available."

So yes: Microsoft recommends **Add shortcut** over **Sync**, "when available".

| Aspect | Add shortcut to My files | Sync button |
|---|---|---|
| Microsoft recommendation | Recommended ("more versatile option when available") | Alternative |
| Scope | Follows your account. Appears in OneDrive on the web, Windows File Explorer, Mac Finder, Teams, OneDrive mobile apps | Per computer. "To sync the files on another computer, go to that computer, and follow these steps again." |
| Performance | "improved performance versus using the sync button" | - |
| Local location | Inside your OneDrive folder (`OneDrive - <Org>`) | A separate folder named after your organization (e.g. `%userprofile%\Contoso`) |
| Can you choose the location? | No (it lives inside your OneDrive folder) **(inference)** | No: "You can't select to sync to a different location." |
| Storage | "Shared folders added to your OneDrive do not use any of your OneDrive storage space. They only count against the folder owner's storage space." | Uses the library's storage **(inference)** |
| Limits | Up to 100 folder shortcuts from a single person's OneDrive or Teams site; up to 1,000 shortcuts across files and folders; folders only, not individual files | No specific limit stated on the page |
| Who can use it | "The procedures in this article are available only to internal users. You can't add shortcuts to folders that are shared with external users." | Guest sync is supported via B2B sync (see Restrictions page) |
| Admin can disable | Yes: `Set-SPOTenant -DisableAddShortcutsToOneDrive $True` | Site may not be set up for sync ("Which library do you want to sync?" screen -> contact IT) |

Recommendation for the skill: use **Add shortcut** first. Fall back to **Sync** if the shortcut option is missing (disabled by admin, external/guest user, folder already added, 100-shortcut limit reached).

### 1A. Add shortcut to My files

Prerequisite: OneDrive sync app installed and signed in with the work/school account (see checklist). The Add shortcut article says you need Edit permission to add shared folders ("If you have Edit permissions to those shared folders, you can add them to the My files section"; in the OneDrive "Shared" view items you can add are marked "Can edit").

**From SharePoint on the web** (Microsoft, verbatim tip):
> "In a shared library in SharePoint or Microsoft Teams, you can select Add shortcut to My files to add a shortcut to the entire library or select the specific folder you want to add, and then select Add shortcut to My files."

Steps:
1. Open the SharePoint site (Microsoft 365 app launcher > SharePoint > site), then **Documents** (or the library).
2. To add the whole library: with nothing selected, select **Add shortcut to My files** in the command bar.
   To add one folder (e.g. the channel's folder): select that folder (one only), then **Add shortcut to My files**.
   - Label note: depending on UI version the button may read "Add shortcut to OneDrive" **(inference)**.
3. Wait for OneDrive to sync it to the computer.

**From Teams** (Microsoft states shortcuts work "In a shared library in SharePoint or Microsoft Teams"; exact Teams button positions are not in the fetched pages):
1. In Teams desktop, go to the team > channel > **Shared** tab (older clients: **Files** tab).
2. Use **Add shortcut to OneDrive / My files** from the toolbar (or from the "..." menu on a folder) **(inference: exact label/location varies by Teams version)**.
3. If not visible, use **Open in SharePoint** from the same tab's toolbar/"..." menu **(inference)** and follow the SharePoint steps above.

**From OneDrive on the web** (Microsoft, work or school):
1. In OneDrive, in the navigation pane, select **Shared > With you**.
2. Find the folder, click the circle on its tile to select it.
3. Select **Add shortcut to My files** (or right-click the folder > **Add shortcut to My files**).

**When the option is not available** (Microsoft):
- "You've already added the folder to your OneDrive, or you have more than one folder selected."
- "The item you're trying to add isn't a folder."
- "You've already added 100 shortcuts in the same document library."

**Optional:** you can rename the shortcut; "The new name you give to the folder is visible only to you" (useful to shorten local paths, see section 4).

**Undo / remove the shortcut** (Microsoft):
- OneDrive on the web: in **My files**, select the shared folder > **Remove shortcut from My files** (or **Remove shortcut**). "This only removes the folder from your OneDrive - it's still accessible from your Shared list and doesn't affect the owner or anyone else sharing the folder."
- Windows File Explorer: select the folder > right-click > **OneDrive** > **Remove shortcut**.
- "If you sync OneDrive to one or more computers, removing a shared folder from your OneDrive also removes it from those computers."
- WARNINGS (Microsoft, verbatim):
  - "If you delete the folder instead, it's deleted from everyone's OneDrive and the folder owner would have to restore it."
  - "When deleting a shortcut using right click, delete or the Delete button from keyboard, ensure all files are closed before in File Explorer. Deleting a Shortcut with any files that are open will result in deletion of some or all files within the Shortcut. This content can be recovered from the OneDrive or SharePoint Recycle Bins"
  - "If you intend to delete a Shortcut from your OneDrive by deleting it from the left navigation pane in Windows, collapse the shortcut before deleting. Deleting an expanded shortcut will delete the folder and its contents for everyone, rather than remove the shortcut for that user."
- macOS: no Finder "Remove shortcut" command is documented; remove it from OneDrive on the web **(inference: safest path on Mac; never drag the shortcut folder to the Trash)**.

### 1B. Sync button

**From SharePoint/Teams in the browser** (Microsoft, main article):
1. "Near the upper left corner of the browser page, select the Microsoft 365 app launcher."
2. "From the menu that opens, select SharePoint or Teams, and then select the site with the files you want to sync."
3. "Select Documents or navigate to the subfolder you want to sync."
4. "Select Sync. (You only need to do this once on a computer to set up syncing on that computer. After you set up syncing, the files sync automatically.)"
5. "If your browser requests permission to use "Microsoft OneDrive," confirm that this is okay."
- The SharePoint training page adds: if Sync is not on the toolbar, "Select the ellipses icon ... and choose Sync from the list of menu items", then "Sign in to OneDrive to start syncing your files and finish OneDrive setup."
- Important: "If a screen appears stating "Which library do you want to sync?", your site hasn't been set up to sync with the OneDrive sync app." -> contact IT.

**From Teams desktop:** channel > **Shared** (or **Files**) tab > **Sync** in the toolbar, or **Open in SharePoint** and use the steps above **(inference: Microsoft's article routes Teams users through the browser/app launcher; the in-Teams button exists in many tenants but is not described on the fetched pages)**.

**Change folders / stop syncing** (Microsoft, Windows):
1. Select the blue OneDrive cloud icon in the Windows taskbar notification area (may be under **Show hidden icons**; if absent, start OneDrive from Start).
2. Select the gear (Help & Settings) > **Settings**.
3. **Account** tab lists all syncing sites.
4. **Choose folders** for that library to change folders, or **Stop sync** next to the site to stop. "(Copies of the files remain on your computer. You can delete them if you want.)"

**macOS:** OneDrive cloud icon in the menu bar > Help & Settings > Settings/Preferences > **Account** tab > Stop sync / Choose folders **(inference by analogy; Microsoft documents the Mac menu-bar > Preferences > Account > Choose folders path in the Files On-Demand and Add-shortcut articles, but the Mac "Stop sync" step was not on the fetched pages)**.

**Other Sync notes (Microsoft):**
- "If a site name includes a character such as ":" that isn't supported in folder names in Windows, files on the site can't be synced."
- Lock icon = synced read-only: "You might not have permission to edit the files, or the library might require checkout or have required columns or metadata. If you change the files on your computer, the changes won't sync."
- Don't move Office files/OneNote notebooks between sites via the local folder (version history is lost); use **Move to / Copy to** on the site.

---

## 2. Where the folder appears locally, and opening it in Claude Code

### Windows
- **Shortcut method:** inside your OneDrive folder. Microsoft: "On a Windows PC, find the OneDrive folder with the name of your organization after it in Windows Explorer. For example, OneDrive - Contoso." Example path from Microsoft: `C:\Users\JaneDoe\OneDrive - Contoso\...`
  - Pattern: `C:\Users\<you>\OneDrive - <Org>\<shortcut name>\...` (shortcut name = library or folder name, unless renamed) **(inference for the last segment)**.
- **Sync method:** "The files then sync to a folder on your PC that has the name of your organization (for example, %userprofile%\Contoso). This folder is automatically added to the left pane in File Explorer." "Each location will appear in a separate subfolder."
  - Pattern: `C:\Users\<you>\<Org>\<Site name> - <Library or folder name>\` **(inference for the subfolder naming)**.
- How to find: File Explorer left pane (OneDrive - <Org> and the <Org> building icon); or right-click the folder > Properties > Location; or address bar for the full path.

### macOS
- Microsoft example path (work/school account): `/Users/janedoe/Library/CloudStorage/OneDrive - Contoso/Projects/2026/Q1/Budget_Report_v3.xlsx`. (The same article's Terminal example writes it as `/Users/janedoe/Library/CloudStorage/OneDrive-Contoso/...`; the on-disk name is commonly `OneDrive-<Org>` while Finder shows "OneDrive - <Org>" **(inference)** - always confirm with `ls`.)
- Since macOS 12.1: "Your OneDrive folder will be visible under Locations in the Finder sidebar."
- **Shortcut method:** `~/Library/CloudStorage/OneDrive-<Org>/<shortcut name>/` (Microsoft: "On a Mac computer, use the Finder to locate the OneDrive folder.") **(inference for the exact path)**.
- **Sync method:** synced libraries go to a separate root, commonly `~/Library/CloudStorage/OneDrive-SharedLibraries-<Org>/<Site name> - <Library>/` **(inference: observed/community-reported; not in Microsoft's support articles)**.
- How to find:
  ```bash
  ls -1 ~/Library/CloudStorage/
  ls -1 ~/Library/CloudStorage/OneDrive-*/
  ```
  Or in Finder: right-click the folder > Get Info > "Where"; or Option+right-click > "Copy ... as Pathname" **(inference)**.
- Note: older OneDrive builds (pre-File Provider) used `~/OneDrive - <Org>` and `~/<Org>`; there may be legacy symlinks/folders **(inference)**.

### Open the folder in Claude Code
- **CLI (macOS/Linux shell)** - quote the path because it contains spaces:
  ```bash
  cd ~/Library/CloudStorage/"OneDrive-Contoso"/"My Team - Channel"
  claude
  ```
- **CLI (Windows PowerShell):**
  ```powershell
  cd "$env:USERPROFILE\OneDrive - Contoso\My Team - Channel"
  claude
  ```
- **Claude Desktop, Code tab:** open the Code tab, choose the option to select a local folder/project, and pick the synced folder via the file dialog (on macOS, press Cmd+Shift+G in the dialog and paste the `~/Library/CloudStorage/...` path, since `Library` is hidden by default) **(inference: Claude Desktop UI labels not verified against Anthropic docs in this research)**.
- macOS may prompt the terminal app for permission to access files managed by OneDrive / File Provider; allow it **(inference)**.

---

## 3. Files On-Demand (why it matters, and how to pin files locally)

### What it is (Microsoft)
- "OneDrive Files On-Demand helps you access all the files in your cloud storage in OneDrive without having to download them and use storage space on your computer."
- Windows: "Starting with OneDrive build 23.066 Files On-Demand is enabled by default for all users."
- macOS: "From macOS 12.1, Files On Demand is part of macOS and cannot be turned off. You can still mark your files as Always Keep on This Device if you need them available when offline."
- Statuses: online-only (cloud icon) - "the file doesn't download to your device until you open it. You can't open online-only files when your device isn't connected to the Internet." Locally available (green check) - downloaded after opening; can revert with Free up space. Always available (green circle with white check) - "Only files that you mark as "Always keep on this device"" - "download to your device and take up space, but they're always there for you even when you're offline."
- "New files or folders created online or on another device appear as online-only to save maximum space. However, if you mark a folder as "Always keep on this device," new files in that folder download to your device as always available files."
- "Desktop search can search for online-only files by name, but it cannot search the contents within online-only files because they aren't stored on the device." (Mac: same for Finder.)
- Windows shows notifications "when Windows automatically downloads online-only files for your apps" (linked article).
- Storage Sense (Windows) can turn locally available files back to online-only after a period; "Always keep on this device" files are exempt **(inference for the exemption; Microsoft states the Storage Sense conversion applies to "these files", i.e. locally-available ones)**.

### Why a local indexing/hashing tool needs files pinned (inference)
- A tool that reads or hashes every file will force each online-only placeholder to download on first read. With many files this is slow, can stall or fail when offline, triggers download notifications, and results vary run to run (some files hydrated, some not).
- Placeholders report a logical size but ~0 bytes on disk (Microsoft: "OneDrive Files On Demand doesn't download all the files to your computer, only a placeholder or link to it"); tools that check size-on-disk or use `stat` blocks may misjudge them.
- Files hydrated "on open" may later be evicted again (Free up space / Storage Sense), so the next run re-downloads.
- Therefore: mark the workspace folder **Always keep on this device** before the first scan, and re-run the tool only after the OneDrive icon shows "up to date".

### How to mark a folder "Always keep on this device"
- **Windows (Microsoft):** in File Explorer, "Right-click a file or folder. Select Always keep on this device or Free up space." Verify: green circle with white check on the folder and its files.
  - Alternative for whole account: OneDrive Settings > **Sync and back up** > **Advanced settings** > Files On-Demand > **Download all files** ("equivalent to choosing ... "Always keep on this device" ... for the entire OneDrive folder"). Not recommended just for one workspace **(inference)**.
- **macOS (Microsoft):** select the folder in Finder, right-click > **Always Keep on This Device**. If the option is missing, relaunch Finder (Control+Option click Finder in Dock > Relaunch, or Force Quit > Finder > Relaunch).
  - Microsoft caveat: "When you mark a file as "Always Keep on This Device" the cloud icon may remain." "Unopened offline cloud file or folder - This file or folder is always available. Both cloud and "Always available" icons are visible." Once opened, the cloud icon disappears.
  - Microsoft: "OneDrive "Always Keep on This Device" files show zero bytes on macOS" can happen in Get Info; see "OneDrive disk space and file size don't match".
- Settings are per device: "Files On-Demand settings are unique to each device".
- Verify from a terminal (inference):
  - macOS: `du -sh "<folder>"` should approach the library size; online-only files contribute ~0. `ls -lO` (BSD flags) may show `dataless` for non-downloaded items.
  - Windows (PowerShell): `attrib` on a file - online-only placeholders carry the Offline/RecallOnDataAccess attributes; pinned files show `P` (pinned) **(inference)**.

### Disk-space caveat
- Pinned files "download to your device and take up space". Check the library size on SharePoint (Site contents / Storage metrics) or OneDrive web before pinning, and pin only the KB folder, not the entire team library **(inference)**.
- If space runs out, sync stops working for new files **(inference)**; free space via **Free up space** on folders you don't need.

---

## 4. Sync caveats relevant to a shared team KB

### Sync latency
- Microsoft gives no SLA/latency figure. Changes sync "automatically" when online; large batches show "syncing" or "processing changes" and "you may need to wait an extended period of time before the sync process can complete."
- Outlook .PST files sync less often (not relevant to a KB).
- Practical guidance **(inference)**: treat the folder as eventually consistent (seconds to minutes; longer for big batches). Before running the tool, check the OneDrive icon says up to date; after the tool writes files, wait for sync to finish before teammates read them. Use Pause/Resume syncing (OneDrive icon > More/gear > Pause syncing 2/8/24 h) only if needed.

### Conflict copies (exact Microsoft behavior)
- Office files (.docx/.xlsx/.pptx): conflicts are resolved in the Office app ("Save a Copy" outside the synced folder, or "Discard" to fetch the server version). A sync icon that persists on a file not actively syncing "indicates a conflict which you must resolve."
- Non-Office files (e.g. .md, .json, .csv, .ttl): "OneDrive automatically keeps both versions. The online version keeps the original file name and is downloaded, and the copy on your computer has your device name appended to the file name such as Report-JOHNS-SURFACE.txt."
  - Naming pattern: `<basename>-<DEVICE-NAME>.<ext>` (example from Microsoft: `Report-JOHNS-SURFACE.txt`).
  - "OneDrive for work or school creates up to 5 conflict versions for non-Office file types." Subsequent conflict copies typically get a numeric suffix, e.g. `<basename>-<DEVICE-NAME>-1.<ext>` **(inference; not stated)**.
- Separate Microsoft article: duplicate files "with your computer name added to the filename" can also mean stale credentials; fix by removing cached credentials (Windows Credential Manager: Generic Credentials entries with "MicrosoftAccount" + username; Mac Keychain: "OneDrive Cached Credential") and restarting OneDrive.
- Microsoft: "You may have sync conflicts if you're uploading multiple files on the OneDrive website at the same time, or if you made changes in your OneDrive folder on another PC that is syncing at the same time. Sync issues can also occur if you edit files offline."
- For the tool **(inference)**: exclude or flag files matching `*-<COMPUTERNAME>.*` / `*-<COMPUTERNAME>-<n>.*` from indexing and surface them to the user; avoid two people (or two machines) editing the same generated file; prefer one writer per file (e.g. per-user notes files, or a single "maintainer" machine for generated indexes).

### Files open in Office / locked files
- Office creates temporary lock files `~$<name>` next to the open document; "any filename starting with ~$" is not allowed to sync, and `.lock` is an invalid name (Microsoft, Restrictions page). Temporary `.tmp` files don't sync.
- "File locked" is a recognized OneDrive status icon (Fix sync problems page).
- Lock icon on synced files = read-only sync (no edit permission, checkout required, required columns/metadata, validation, draft item security). Library settings that force read-only sync include Require Check Out, Validation columns, required columns, Draft Item Security, Content Approval; edit sync needs permission level "Contribute or higher".
- **(inference)** The tool should skip `~$*` files, tolerate read errors on files open elsewhere, and not rewrite Office binaries while a teammate has them open (co-authoring happens via Office, not via the file system).

### Path length limits (Microsoft)
| Platform | Max path |
|---|---|
| Windows File Explorer / default Windows file system | 260 characters (names up to 255) |
| Windows Office desktop apps | 256 characters (260 UTF-16 WCHARs) |
| OneDrive and SharePoint (cloud) | 400 characters (entire decoded path incl. file name) |
| OneDrive sync | 520 characters (local path up to 400 + OneDrive root folder up to 120); over 520 -> "path is too long" notification and sync quits until resolved |
| macOS Finder | 1,024 characters (names up to 255) |
| macOS Office | 1,024 UTF-8 bytes |
- Microsoft specifically warns: "When you add a shortcut to OneDrive for a shared SharePoint library or Teams channel folder, the shortcut contents sync to your device under your OneDrive folder. If the shared library has deep nesting or long folder names, the local path can quickly exceed 260 characters". Advice: shortcut a subfolder rather than the whole library, flatten structure, rename the shortcut to a shorter name.
- Special characters/spaces are URL-encoded in SharePoint (space -> %20) and count toward the 400 limit.
- Check on macOS: `echo -n "<full path>" | wc -c`. Windows: `Get-ChildItem -Recurse | Where-Object { $_.FullName.Length -gt 260 }`.

### Invalid characters and names (Microsoft)
- Not allowed in file/folder names: `" * : < > ? / \ |`; leading/trailing spaces not allowed. (Since 28 January 2025, "Invalid characters are now supported on OneDrive for Mac", but the restriction still matters for Windows teammates - **(inference)**.)
- Some orgs don't support `#` and `%`. Office desktop can't save into folders whose name contains `;`.
- Invalid names: `.lock`, `CON`, `PRN`, `AUX`, `NUL`, `COM0`-`COM9`, `LPT0`-`LPT9`, `_vti_` (anywhere in name), `desktop.ini`, any name starting with `~$`; `forms` not allowed at the library root.
- `desktop.ini` and `.ds_store` normally don't sync. Admins may block other file types.
- Network/mapped drives can't be the sync location; "OneDrive doesn't support syncing using symbolic links or junction points." **(inference)**: a tool must not create symlinks inside the synced folder and expect them to sync; the Python venvs / node_modules / .git directories should not live in the synced folder.
- macOS: "Case-sensitive formatted disk volume isn't supported"; Files On-Demand needs APFS. Windows: folders must not have `SetCaseSensitiveInfo` enabled. **(inference)**: avoid two files differing only by case.

### Size and item-count limits (Microsoft)
- Max file size for upload/download/sync: 250 GB.
- "For optimum performance, we recommend syncing no more than a total of 300,000 items across your cloud storage." (Preview: up to 1,000,000 items per sync instance on Windows 11 with specific hardware; roll-out started 22 April 2026.)
- Sharing a folder: total sub-items limited to 50,000. Web UI copies up to 2,500 files at a time.
- Thumbnails/PDF previews not generated over 100 MB.
- Accounts: max 1 personal + 9 work/school accounts per device; "For MacOS devices, only a single business account from the same organization can be in sync at any given time."
- Windows: File Explorer shows only "the first 35 characters of a site library's name and site name combination" for synced libraries (display only).

### Timestamps / mtime
- Microsoft (official) only states: "You may see a difference between folder dates and content dates. This is because the folder date refers to when the folder itself was created or changed, not when something inside of it has changed. You may notice this when syncing an old folder from the cloud."
- Microsoft Q&A community threads report file/folder "Date modified" changing on sync, re-download, or opening Office files **(not official documentation; treat as known risk)**.
- **(inference)** Do not use mtime as the change-detection key for the KB; use content hashes (e.g. SHA-256) and store them in the tool's manifest. Note that hashing requires files to be downloaded (section 3).

### Deletion semantics (Microsoft)
- "When you delete an online-only file from your device, you delete it from your OneDrive on all devices and online." Work/school items can be restored from the recycle bin for up to 93 days.
- Files deleted from a shared folder on OneDrive.com go to the owner's recycle bin; "Only the owner of a shared folder can restore an item deleted from the folder."
- **(inference)** A tool that "cleans up" or regenerates folders will delete content for the whole team; restrict deletions to tool-owned output paths.

---

## 5. Checklist for the skill (with verification)

1. **Confirm account type and access.** User signs in to Teams/SharePoint with the work/school account and can open the channel's files in the browser; they need edit rights (Contribute or higher) for read/write.
   Verify: in SharePoint the library shows "Edit"/upload options; after sync, files have no lock icon.
2. **OneDrive app installed, running, signed in to the work account.**
   Verify: Windows - blue cloud icon in notification area; macOS - cloud icon in menu bar; its panel shows the org account and "up to date". macOS: `ls ~/Library/CloudStorage/` lists `OneDrive-<Org>` **(inference for exact name)**.
3. **Identify the target.** Teams channel > Shared/Files tab > Open in SharePoint; note site, library, and the channel folder. Prefer a dedicated KB subfolder over the whole library (path length, disk, conflicts).
   Verify: user can state the SharePoint URL of the folder.
4. **Check path length and names in advance.** Estimate local root + folder depth; aim well below 260 chars for Windows teammates. Check names for `" * : < > ? / \ |`, leading/trailing spaces, `#`/`%`.
   Verify: run the path-length one-liner (section 4) after sync; no "path is too long" notification.
5. **Add shortcut (preferred).** In SharePoint/Teams select the folder > **Add shortcut to My files**. Optionally rename the shortcut to something short.
   Verify: OneDrive web > My files shows the folder with the shortcut (link) icon; it appears under `OneDrive - <Org>` locally.
6. **Fallback: Sync button** if shortcut is unavailable (external user, disabled by admin, limit reached).
   Verify: OneDrive Settings > Account lists the site/library; folder appears under `%userprofile%\<Org>` (Windows) or the CloudStorage shared-libraries root (macOS, inference).
7. **Find the exact local path.** Windows: File Explorer > folder > address bar. macOS: `ls -1 ~/Library/CloudStorage/` then `ls` into it.
   Verify: `ls`/`dir` lists the same files the user sees in Teams.
8. **Pin the folder: Always keep on this device.** Right-click the folder > Always keep on this device (Windows File Explorer / macOS Finder).
   Verify: green circle with white check (Windows); "always available" icon on Mac (cloud icon may remain until opened - expected); `du -sh` on the folder roughly matches the library size **(inference)**.
9. **Check disk space** before/after pinning.
   Verify: free space on the volume comfortably exceeds the folder size (`df -h ~` / File Explorer This PC).
10. **Wait for initial sync to finish.**
    Verify: OneDrive panel shows "up to date"; no red-circle error icons; no "processing changes" for the folder.
11. **Open the folder in Claude Code.** `cd "<path>"` then `claude` (quote paths with spaces), or select the folder in Claude Desktop's Code tab.
    Verify: Claude Code's working directory is the synced folder (e.g. `pwd` shows the CloudStorage / OneDrive path); grant macOS file-access prompts if shown **(inference)**.
12. **Round-trip write test.** Create a small test file (e.g. `_sync-test-<user>.md`) from the tool; confirm it appears in the Teams channel's Shared/Files tab and that a teammate (or the browser) sees it; then delete it and confirm deletion propagates.
    Verify: file visible in browser within a short time; disappears after delete.
13. **Conflict hygiene.** Explain the `<name>-<DEVICE>.<ext>` conflict copies and up-to-5 limit; agree on one writer per generated file; configure the tool to ignore `~$*`, `*.tmp`, `.DS_Store`, `desktop.ini`, and to report `*-<COMPUTERNAME>*` files.
    Verify: `find . -name '*-<COMPUTERNAME>*'` (or PowerShell `Get-ChildItem -Recurse -Filter "*-$env:COMPUTERNAME*"`) returns nothing after setup.
14. **Change detection by content hash, not mtime.** Configure/confirm the tool uses hashes.
    Verify: re-running the tool without content changes reports zero changed files.
15. **Know how to undo.** Shortcut: OneDrive web > My files > Remove shortcut (never delete the folder itself; on Windows collapse before deleting from nav pane; close files first). Sync: OneDrive Settings > Account > Stop sync (local copies remain).
    Verify: user can point to where they would do it; after removal, the folder disappears locally but remains in Teams.

---

## 6. Sources (all fetched 2026-10-04)

Primary:
- Sync SharePoint and Teams files with your computer - https://support.microsoft.com/en-us/sharepoint/sync/sync-sharepoint-and-teams-files-with-your-computer (also at https://support.microsoft.com/en-us/office/sync-sharepoint-and-teams-files-with-your-computer-6de9ede8-5b6e-4503-80b2-6190f3354a88)

Linked / follow-up Microsoft pages:
- Add shortcuts to shared folders in OneDrive - https://support.microsoft.com/en-us/onedrive/add-shortcuts-to-shared-folders-in-onedrive (linked as /en-us/topic/d66b1347-99b7-4470-9360-ffc048d35a33)
- Sync SharePoint files and folders (SharePoint training; Windows and macOS tabs) - https://support.microsoft.com/en-us/onedrive/sync/sharepoint-training/sync-sharepoint-files-and-folders
- Save disk space with OneDrive Files On-Demand for Windows - https://support.microsoft.com/en-us/onedrive/save-disk-space-with-onedrive-files-on-demand-for-windows
- Save disk space with OneDrive Files On-Demand for Mac - https://support.microsoft.com/en-us/onedrive/save-disk-space-with-onedrive-files-on-demand-for-mac
- Fix OneDrive Files On-Demand issues on macOS 12.1 or later - https://support.microsoft.com/en-us/onedrive/fix-onedrive-files-on-demand-issues-on-macos-12-1-or-later
- Restrictions and limitations in OneDrive and SharePoint - https://support.microsoft.com/en-us/onedrive/restrictions-and-limitations-in-onedrive-and-sharepoint
- What are the file path length limits? - https://support.microsoft.com/en-us/onedrive/what-are-file-path-length-limits
- OneDrive sizes and dates don't match - https://support.microsoft.com/en-us/onedrive/onedrive-sizes-and-dates-don-t-match
- Duplicate files in OneDrive - https://support.microsoft.com/en-us/onedrive/duplicate-files-in-onedrive
- Fix OneDrive sync problems - https://support.microsoft.com/en-us/onedrive/fix-onedrive-sync-problems
- What do the OneDrive icons mean? - https://support.microsoft.com/en-us/onedrive/what-do-the-onedrive-icons-mean
- File storage in Microsoft Teams - https://support.microsoft.com/en-us/teams/files/file-storage-in-microsoft-teams
- Resolve sync issues in OneDrive for work or school (Microsoft Learn; source of conflict-copy naming and "up to 5 conflict versions") - https://learn.microsoft.com/en-us/troubleshoot/sharepoint/sync/troubleshoot-sync-issues

Not reachable:
- "Sync files with OneDrive on Mac OS X" (linked from the main article as /en-us/topic/d11b9f29-00bb-4172-be39-997da46f913f) redirects to a 404 as of 2026-10-04; macOS details were taken from the Files On-Demand for Mac, macOS 12.1, path-length and SharePoint training pages instead.

Non-official (used only to flag risks, marked as such):
- Microsoft Q&A community threads on "Date modified" changing after OneDrive sync, e.g. https://learn.microsoft.com/en-us/answers/questions/5597251/ and https://learn.microsoft.com/en-us/answers/questions/5235111/
- Microsoft Tech Community / Q&A threads mentioning `~/Library/CloudStorage/OneDrive-SharedLibraries...`, e.g. https://techcommunity.microsoft.com/discussions/onedriveforbusiness/macos-14-8-1-onedrive---timestamped-sync-root-directory/4489486
