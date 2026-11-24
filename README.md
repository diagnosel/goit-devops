# Homework 3: Linux administration

Neoversity DevOps CI/CD coursework.
[Assignment in GoIT LMS](https://www.edu.goit.global/uk/learn/28179789/32217374/32217381/homework).

`install_dev_tools.sh` checks for Docker, Docker Compose, Python 3.9+ and Django.
It installs missing tools and skips tools that are already available.

## Run

Use an Ubuntu or Debian lab with internet access and root or sudo access.
The script rejects macOS and other Linux distributions.

```bash
chmod u+x install_dev_tools.sh
./install_dev_tools.sh
```

Docker packages come from Docker's official APT repository.
Python comes from the OS repository when Python 3.9+ is missing.
Django is installed with pip in `.venv` beside the script when it is not already available.
Existing distribution-managed Docker packages can conflict with Docker's repository.
The script stops when it finds those conflicts. It does not remove them.

To use the Django environment created by the script:

```bash
source .venv/bin/activate
python -m django --version
```

Run `deactivate` to leave this Python environment.
If Django was already available in system Python, the script keeps it and does not create `.venv`.

## Verification

Tested on 25 November 2026 in an isolated Ubuntu 24.04.4 LTS ARM64 VM.

| Tool | Observed version |
| --- | --- |
| Docker client and server | 29.10.1 |
| Docker Compose | 5.8.0 |
| Python | 3.12.3 |
| Django | 6.1.3 |

- The first script run completed successfully.
- Docker ran `hello-world` directly and through Compose.
- A new Django project passed `manage.py check`. Its start page returned HTTP 200 through Django's test client.
- The second script run skipped all four tools. Its Bash trace contained no `apt-get` or `pip install` calls.
- System and Python package lists were identical before and after the second run.

Python was already present in the VM. Installing missing or older Python was not tested.
Debian, other Ubuntu releases and x86_64 were not tested.
The versions above describe the test run. The script uses available package versions rather than fixed versions.

To check Docker after installation:

```bash
sudo docker run --rm hello-world
```

For a repeated run, leave `.venv` with `deactivate` if it is active, then run `./install_dev_tools.sh` again.
Expect a skip message for each tool.
