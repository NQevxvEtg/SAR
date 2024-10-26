To run a Bash script asynchronously on over 100 servers using Ansible, you'll need to create a playbook that executes the script without waiting for it to finish on each server. Here's how you can accomplish this:

1. **Create an Ansible Playbook**: Write a playbook that defines the tasks you want to execute.

2. **Copy the Bash Script to Remote Servers**: Use the `copy` module to transfer your Bash script to the remote servers.

3. **Execute the Script Asynchronously**: Use the `shell` or `command` module with `async` and `poll` parameters to run the script without waiting for it to complete.

4. **Adjust Ansible Forks for Parallelism**: Increase the `forks` parameter to run tasks on multiple servers in parallel.

Below is a step-by-step guide:

---

### **1. Write the Ansible Playbook**

Create a YAML file (e.g., `run_script.yml`) with the following content:

```yaml
- name: Run Bash script asynchronously on multiple servers
  hosts: all
  become: yes  # Use this if you need sudo privileges
  tasks:

    - name: Copy Bash script to remote servers
      copy:
        src: /path/to/local_script.sh
        dest: /tmp/remote_script.sh
        mode: '0755'

    - name: Execute the Bash script asynchronously
      shell: /tmp/remote_script.sh
      async: 3600  # Maximum runtime in seconds
      poll: 0      # Don't wait for the task to complete
```

**Explanation:**

- **`copy` Module**: Transfers your local Bash script to the remote servers.
- **`shell` Module with `async` and `poll`**:
  - `async: 3600`: Allows the task to run for up to 1 hour.
  - `poll: 0`: Tells Ansible not to wait for the task to finish (fire and forget).

---

### **2. Adjust Ansible Forks for Parallel Execution**

By default, Ansible runs with 5 forks, meaning it will manage 5 servers in parallel. To run the playbook on 100+ servers efficiently, increase the number of forks.

**Option A: Command Line**

Run the playbook with the `--forks` option:

```bash
ansible-playbook -i inventory.ini run_script.yml --forks 50
```

**Option B: Update `ansible.cfg`**

Modify your `ansible.cfg` file to set a higher default:

```ini
[defaults]
forks = 50
```

**Note:** Be cautious when setting a high number of forks, as it can consume significant resources on your control machine.

---

### **3. Execute the Playbook**

Run the playbook using the `ansible-playbook` command:

```bash
ansible-playbook -i inventory.ini run_script.yml
```

- **`-i inventory.ini`**: Specifies your inventory file containing the list of servers.
- **`run_script.yml`**: The playbook you created.

---

### **4. Monitor the Tasks (Optional)**

If you want to monitor the status of the asynchronous tasks, you can use the `async_status` module in a separate play or task.

```yaml
- name: Check async task status
  async_status:
    jid: "{{ item.ansible_job_id }}"
  register: job_result
  with_items: "{{ async_results }}"
```

---

### **Additional Tips**

- **Ensure SSH Access**: Make sure your Ansible control machine can SSH into all the target servers without manual password entry (use SSH keys or SSH agent).
- **Sudo Privileges**: If your script requires elevated privileges, ensure you have `become: yes` in your playbook and appropriate sudo permissions.
- **Resource Management**: Monitor the resource utilization on your control machine to prevent overload when running tasks on many servers simultaneously.


---

Here's how you can modify your existing playbook to include monitoring of the asynchronous tasks:

---

### **Updated Ansible Playbook with Monitoring**

```yaml
- name: Run Bash script asynchronously on multiple servers
  hosts: all
  become: yes  # Use this if you need sudo privileges
  tasks:

    - name: Copy Bash script to remote servers
      copy:
        src: /path/to/local_script.sh
        dest: /tmp/remote_script.sh
        mode: '0755'

    - name: Execute the Bash script asynchronously
      shell: /tmp/remote_script.sh
      async: 3600  # Maximum runtime in seconds
      poll: 0      # Don't wait for the task to complete
      register: async_task_result

    - name: Wait for the asynchronous task to complete
      async_status:
        jid: "{{ async_task_result.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 60       # Number of retries
      delay: 10         # Delay between retries in seconds
```

**Explanation:**

- **`register: async_task_result`**: Stores the result of the asynchronous task, including the job ID (`ansible_job_id`), which is needed to monitor the task.
- **`async_status` Module**: Checks the status of the asynchronous job using the job ID.
- **`until`, `retries`, `delay`**: Implements a loop that checks the task status until it's finished or the retries are exhausted.

---

### **Option: Separate Play within the Same Playbook**

Alternatively, you can split the execution and monitoring into separate plays within the same playbook:

```yaml
- name: Run Bash script asynchronously on multiple servers
  hosts: all
  become: yes
  tasks:

    - name: Copy Bash script to remote servers
      copy:
        src: /path/to/local_script.sh
        dest: /tmp/remote_script.sh
        mode: '0755'

    - name: Execute the Bash script asynchronously
      shell: /tmp/remote_script.sh
      async: 3600
      poll: 0
      register: async_task_result

- name: Monitor asynchronous tasks
  hosts: all
  gather_facts: no  # Skip gathering facts to speed up the play
  tasks:

    - name: Check async task status
      async_status:
        jid: "{{ async_task_result.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 60
      delay: 10
```

**Explanation:**

- **Separate Plays**: The first play runs the script asynchronously, and the second play monitors its completion.
- **`gather_facts: no`**: Disables fact gathering for the monitoring play to make it run faster.

---

### **Key Points**

- **Single Playbook**: Keeping both execution and monitoring tasks in the same playbook simplifies management and execution.
- **Monitoring**: By including the monitoring steps, you can track the completion of the asynchronous tasks and handle any errors or retries as needed.
- **No Need for Separate YAML File**: Unless you have a specific reason to separate them (e.g., different execution times, separate runs), it's more efficient to keep them together.

---

### **How to Run the Playbook**

Execute the playbook as before:

```bash
ansible-playbook -i inventory.ini run_script.yml --forks 50
```

---

### **Additional Tips**

- **Handling Multiple Servers**: When dealing with multiple servers, ensure that the `register` variables (like `async_task_result`) are properly scoped. By default, they are scoped per host.
- **Customizing Retries and Delays**: Adjust the `retries` and `delay` parameters based on how long your script is expected to run.
- **Error Handling**: You can add error handling to manage failed tasks or take corrective actions if needed.


