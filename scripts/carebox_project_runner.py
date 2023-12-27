#!/usr/bin/env python3
import subprocess
from time import sleep
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


# run carebox django project
def run_carebox():
    carebox_cmdline = ["python", "manage.py", "runserver", "0.0.0.0:8000"]
    carebox_running = is_process_running(carebox_cmdline)

    if carebox_running:
        print("Carebox Project:")
        print("- Carebox project is running.")
    else:
        print("- Carebox project is not running")
        print("- Starting Carebox project...")

        # Use subprocess.Popen to run the shell command in the background
        shell_command = "./scripts/carebox_runner.sh"
        subprocess.Popen(
            shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )


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


# run carebox dramatiq django project
def run_carebox_dramatiq():
    dramatiq_process_name = "dramatiq"
    carebox_dramatiq_running = is_process_running(name=dramatiq_process_name)

    if carebox_dramatiq_running:
        print("Carebox Dramatiq Project:")
        print("- Carebox dramatiq project is running.")
    else:
        print("- Carebox dramatiq project is not running")
        print("- Starting Carebox dramatiq project...")

        # Use subprocess.Popen to run the shell command in the background
        shell_command = "./scripts/carebox_dramatiq_runner.sh"
        subprocess.Popen(
            shell_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )


# kill carebox django project
def kill_carebox():
    carebox_cmdline = ["python", "manage.py", "runserver", "0.0.0.0:8000"]
    carebox_cmdline_full = [
        "/home/carebox/project/carebox-version1/venv/bin/python",
        "manage.py",
        "runserver",
        "0.0.0.0:8000",
    ]
    carebox_running = is_process_running(carebox_cmdline)
    if not carebox_running:
        carebox_running = is_process_running(carebox_cmdline_full)

    if carebox_running:
        is_stopped = False
        for proc in psutil.process_iter(["name", "cmdline"]):
            try:
                if proc.cmdline() == carebox_cmdline:
                    proc.kill()
                    print("- Carebox django project stopped")
                    is_stopped = True
                if proc.cmdline() == carebox_cmdline_full:
                    proc.kill()
                    print("- Carebox django project stopped")
                    is_stopped = True
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                is_stopped = False
        return is_stopped
    else:
        print("- Carebox django project not running.")


# kill carebox dramatiq django project
def kill_carebox_dramatiq():
    dramatiq_process_name = "dramatiq"
    carebox_dramatiq_running = is_process_running(name=dramatiq_process_name)
    is_stopped = False
    if carebox_dramatiq_running:
        for proc in psutil.process_iter(["name", "cmdline"]):
            try:
                if proc.name() == dramatiq_process_name:
                    proc.kill()
                    is_stopped = True
            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                return False
        if is_stopped:
            print("- Carebox dramatiq process stopped")
            return True
    else:
        print("- Carebox dramatiq project not running.")


def main():
    present_time = datetime.now()
    print(f"Script running at - {present_time.strftime("%I:%M %p - %d %b %Y")}")

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

    print("Podman Container:")
    if working_hour and container_running:
        print("- Container running.")
        run_carebox()
        run_carebox_dramatiq()

    elif working_hour and not container_running:
        print("- Starting all containers.")
        count = 0

        while not container_running and count < 3:
            subprocess.run(["podman", "container", "start", "--all"])
            container_running = is_container_running(container_name)
            count = count + 1
            sleep(3)

        container_running = is_container_running(container_name)
        if not container_running:
            print("- Error found when trying to run container!")
            exit()
            # Project stop code...
        else:
            run_carebox()
            run_carebox_dramatiq()

    elif not working_hour and container_running:
        print("- Container running.")
        # stop container and carebox
        kill_carebox()
        sleep(3)
        kill_carebox_dramatiq()
        sleep(3)
        print("- Stopping Containers.")
        subprocess.run(["podman", "container", "stop", "--all"])

    elif not working_hour and not container_running:
        kill_carebox()
        kill_carebox_dramatiq()

    # code cli runner
    run_code_cli()
    print("\n***** END *****\n")


if __name__ == "__main__":
    main()
