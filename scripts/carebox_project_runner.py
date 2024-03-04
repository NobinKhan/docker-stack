#!/usr/bin/env python3
import subprocess
import psutil
from datetime import datetime, time


# Use subprocess to get container state
def is_container_running(container_name: str) -> bool:
    try:
        container_status = subprocess.check_output(
            ["podman", "inspect", "--format={{.State.Status}}", container_name],
            text=True,
        ).strip()
        if container_status == "running":
            return True
    except subprocess.CalledProcessError as error:
        print(error)
    return False


# Use psutil to get process running status
def is_process_running(command: list = None, name: str = None) -> bool:
    """Checks if a process with the given command is running."""
    for proc in psutil.process_iter(["name", "cmdline"]):
        try:
            if command:
                if proc.cmdline() == command:
                    return True
            elif name:
                if proc.name() == name:
                    return True

        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            return False
    return False


# Check working hour
def is_working_hour(
    present_time: datetime, working_start: time, working_end: time, non_working_day: str
) -> bool:
    # Get current time and weekday
    current_time = present_time.strftime(
        "%H%M"
    )  # Change format to allow numerical comparison
    current_day = present_time.strftime("%A")

    # Check if current time is within working hours and not Friday
    if current_day != non_working_day:
        current_time_obj = datetime.strptime(current_time, "%H%M").time()
        if working_start <= current_time_obj <= working_end:
            print("- It's Working Time...")
            return True
        else:
            print("- It's Not Working Time...")
    return False


# run code-cli
def run_code_cli():
    code_cmdline = ["code", "tunnel"]
    code_running = is_process_running(code_cmdline)

    if code_running:
        print("Code cli:")
        print("- Code cli is running.")
    else:
        print("- Code cli is not running")
        print("- Starting code cli...")

        # Use subprocess.Popen to run the shell command in the background
        shell_command = "code tunnel >> /home/carebox/logs/code_cli.log 2>&1"
        subprocess.Popen(
            shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )


def main():
    present_time = datetime.now()
    print("\n\n***** START *****")
    print(f"Script running at - {present_time.strftime("%I:%M %p - %d %b %Y")}\n")

    # Define working hours range and non-working day
    working_start = time(8, 45)
    working_end = time(17, 15)
    non_working_day = "Friday"

    # check working hour
    working_hour = is_working_hour(
        present_time, working_start, working_end, non_working_day
    )

    # Check container state
    container_name = "postgresql"
    container_running = is_container_running(container_name)
    carebox_running = is_container_running("carebox")

    # Starting containers
    if working_hour and (not container_running or not carebox_running):
        subprocess.run(["./scripts/containers.sh"])

    # Stoping containers
    elif not working_hour and (container_running or carebox_running):
        # stop container and carebox
        subprocess.run(["podman", "kill", "-a"])

    # starting code cli
    run_code_cli()
    print("\n***** END *****\n")


if __name__ == "__main__":
    main()
