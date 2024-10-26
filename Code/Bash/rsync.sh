### 1. **Basic Local File Synchronization**
To synchronize directories locally (e.g., copying from `/source` to `/destination`):
```bash
rsync -av /source/ /destination/
```
- **Options**:
  - `-a` (archive): preserves permissions, timestamps, symbolic links, etc.
  - `-v` (verbose): displays detailed progress.

---

### 2. **Remote Synchronization Over SSH**
To synchronize files from a local directory to a remote server using SSH:
```bash
rsync -av -e ssh /local_directory/ user@remote_host:/remote_directory/
```
- **Options**:
  - `-e ssh`: specifies SSH as the transfer protocol.
  - Replace `user` and `remote_host` with the username and IP/hostname of the remote server.

---

### 3. **Compressing Data During Transfer**
To speed up transfer on slower networks, use compression with `-z`:
```bash
rsync -avz /source/ user@remote_host:/destination/
```
- **Option**: `-z` (compress): compresses data in transit.

---

### 4. **Limiting Bandwidth Usage**
To restrict bandwidth, use `--bwlimit`. For example, limit to 500 KB/s:
```bash
rsync -av --bwlimit=500 /source/ /destination/
```
- **Option**: `--bwlimit=500` limits bandwidth to 500 KB/s (useful for networks shared with others).

---

### 5. **Using `rsync` to Resume Partial Transfers**
To resume an interrupted transfer, use `--partial`:
```bash
rsync -av --partial /source/ /destination/
```
- **Option**: `--partial` retains partially transferred files, resuming where left off.

---

### 6. **Whole-File Transfer for Faster Performance**
For networks where rechecking files isn’t needed (skipping diff checks), use `-W`:
```bash
rsync -avW /source/ /destination/
```
- **Option**: `-W` transfers entire files, bypassing differential transfers (good for large files with minor changes).

---

### 7. **Deleting Files on Destination Not Present on Source**
To make the destination exactly match the source by deleting extraneous files, use `--delete`:
```bash
rsync -av --delete /source/ /destination/
```
- **Option**: `--delete` removes files from the destination not present in the source, achieving true synchronization.

---

### 8. **Showing Progress During Transfer**
To display progress, use `--progress`:
```bash
rsync -av --progress /source/ /destination/
```
- **Option**: `--progress` shows transfer progress for each file.

---

### 9. **Backing Up with Hard Links**
To create incremental backups efficiently, with hard links to unchanged files, use:
```bash
rsync -a --link-dest=/path/to/previous_backup /source/ /path/to/new_backup/
```
- **Option**: `--link-dest` creates hard links to files that are unchanged from the previous backup, saving space and time.

---

### 10. **Excluding Files or Directories**
To exclude specific files or directories, use `--exclude`:
```bash
rsync -av --exclude='*.log' /source/ /destination/
```
- **Option**: `--exclude='*.log'` excludes all `.log` files from transfer.

