ndupes (Nim Duplicate File Eliminator)
=================================================
A minimalist, high-efficiency duplicate file management tool
designed for extreme memory-constrained environments. (RAM 200-500MB)


🚀 Overview
----------------------
ndupes scans a directory and consolidates duplicate files using hard links.

Unlike traditional tools, it is optimized for systems where
memory and I/O are limited resources
(e.g., Raspberry Pi, home servers with massive HDD arrays).


✨ Key Features
---------------------
- Ultra-Low Memory Footprint: Maintains a Resident Set Size (RES) under 10MB
    even when processing 300,000+ files.
- Physical Entity Awareness (inode-wise): Calculates the cryptographic
    hash only once per physical file. If multiple paths share the same inode,
    the hash is propagated without redundant I/O.
- Intelligent Hard Link Consolidation: When merging duplicates,
    it prioritizes the file with the highest link count ( `st_nlink` ) as the
    master, preserving existing structures.
- Database-Driven Engine: Uses SQLite3 for intermediate data management,
    leveraging indexed queries to bypass the $O(N^2)$ complexity of
    naive comparisons.
- Terminal Adaptive UI: Features a progress bar that dynamically scales
    to your terminal width, with clean separation
    between progress (stdout) and logs (stderr).


🛠 Installation
----------------------
Built with Nim. It is recommended to use the ARC/ORC memory management
for the best performance in low-RAM scenarios.

```Bash
nimble build
```


📖 Usage
----------------------
To keep the system responsive for other tasks, it is highly recommended to
run with low CPU and I/O priority:

```Bash
nice -n 19 ionice -c 3 ./ndupes /path/to/target/directory > ndupes.log
```


⌨️ Command Line Options
-------------------------------
ndupes is designed to be simple and predictable.
It accepts a target directory as a positional argument and supports
the following flags:

| Option | Long Flag  | Description |
|--------|------------|-------------|
| -h | --help         | Show the help message and exit. |
| -V | --version      | Display the current version of ndupes. |
| -v | --verbosity    | Specify the log output level (0-70) for debugging purpose |
| .  | --apply        | Making changes |
| .  | --db           | Specify statistic DB file name, default: ndupes.db in current dir. |
| .  | --dump         | Dump DB contents into CSV |
| .  | --cont-hash    | Run hash process using remained DB |
| .  | --cont-link    | Run hardlink process using remained DB |
| .  | --until-listup | Stop running after list-up process |
| .  | --until-hash   | Stop running after hash process |
| -q | --quiet        | (Under construction) Suppress the progress bar (useful for cron jobs/logs). |


### Example Commands
Standard execution with low priority:

```bash
nice -n 19 ionice -c 3 ./ndupes --apply /mnt/storage
```

Testing with a dry-run to see potential savings:

```bash
./ndupes /home/user/data
./ndupes --dump
```

Running in a script and logging to a file:

```bash
./ndupes --quiet /data >> scan.log 2>&1
```


⚙️ How it Works
----------------------
1. Collect: Traverses the filesystem to gather metadata
    (size, inode, device, nlink) into SQLite.
2. Hash: Identifies files with identical sizes but different inodes.
    Calculates hashes only for the unique physical files.
3. Link: Performs the link() system call to replace duplicates with hard links,
    targeting the "major count" (highest nlink) files first.


🗄 Database Optimizations
-------------------------------
The internal SQLite schema uses specialized indexes to ensure scalability:

- `idx_file_identity` on (device, inode):
    Instant hash propagation across hard links.

- `idx_file_size` on (size): Rapidly narrows down duplicate candidates.


📝 Development Philosophy
-------------------------------
- Atomic Commits: Data is committed per-file. While this increases
    I/O overhead during the collection phase,
    it ensures that memory remains clean and that the database is always
    in a recoverable state in case of interruption.
- ZRAM Synergy: Optimized to work alongside ZRAM to prevent
    physical swap thrashing on SD cards or HDDs.
    In my case, Swap file on the same bus cause high I/O access and
    freeze my system.


----


### Why the "Major Count" Strategy?
By linking to the file that already has the most links,
we respect existing data structures and minimize the risk of hitting
filesystem-specific hard link limits (e.g., 65,000 on ext4)
while maximizing storage reclamation.


---


📊 Actual Memory Usage
----------------------------
Here is the running log on reducing 500GB HDD content
in my Raspberry Pi 3B+ server (1GB RAM):

| run | time  | memory usage | ndupes progress  |
|---|---------|--------------|-------------------|
| 1 |   1h35m | 5.2MB        | collecting 5,000 files |
| 2 |     12m | 7.0MB        | collecting 1,000 files |
| 2 |1d23h31m | 10.7MB       | collecting 160,000 files |
| 2 |3d18h37m | 34.7MB       | collecting 300,000 files |
| 2 |5d 3h58m | 46MB         | calculate 18,339 files hash |
| 2 |6d 2h48m | 76.3MB       | calculate 22,331 files hash |


**Note:** Run #2 is v0.1.0. Even when handling 500GB of storage,
memory usage is strictly capped under 50.0MB thanks to Nim's efficient
memory management and SQLite's optimized page cache.


---


🏗️ Todos
-------------------------------
- [ ] add DB index to speed up for query during hashing
- [ ] add DB index to speed up for query during linking


---


⚖️ License
-----------------------------------------
MIT, see [LICENSE](LICENSE) file


---


Information
-----------------------------------------
If you have attract or thank to this project,
Welcome to help or support with your donations.


<a href="bitcoin:39Qx9Nffad7UZVbcLpVpVanvdZEQUanEXd?message=thank-for-pdf-toc-outlines&amount=0.000035">
  <img src="https://github.com/user-attachments/assets/abce4347-bcb3-42c6-a9e8-1cd12f1bd4a5" />
  bitcoin:39Qx9Nffad7UZVbcLpVpVanvdZEQUanEXd
</a>

<br />or<br />

<a href="ethereum:0x9d03b1a8264023c3ad8090b8fc2b75b1ba2b3f0f?value=0.002">
  <img src="https://github.com/user-attachments/assets/d1bdb9a8-9c6f-4e74-bc19-0d0bfa041eb2" />
  ethereum:0x9d03b1a8264023c3ad8090b8fc2b75b1ba2b3f0f
</a>

