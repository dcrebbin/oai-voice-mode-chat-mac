import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import requests
import json
import time
from threading import Thread
from application_state import ApplicationState
from constants import HIGHLIGHT_RULES, convert_string_to_markdown

class ContentView:
    def __init__(self, notebook):
        self.frame = ttk.Frame(notebook)
        self.messages = []
        self.is_listening = False
        self.message_ids = []
        self.conversation_id = ""
        self.conversation_title = ""
        self.error_text = None

        self.setup_ui()

    def setup_ui(self):
        self.text_area = tk.Text(self.frame, wrap='word', state='disabled')
        self.text_area.pack(expand=True, fill='both')

        self.retrieve_button = ttk.Button(self.frame, text="Retrieve latest chat", command=self.toggle_listening)
        self.retrieve_button.pack(side='left', padx=5, pady=5)

        self.clear_button = ttk.Button(self.frame, text="Clear", command=self.clear_conversation)
        self.clear_button.pack(side='left', padx=5, pady=5)

    def toggle_listening(self):
        self.is_listening = not self.is_listening
        if self.is_listening:
            self.start_listening()
        else:
            self.stop_listening()

    def start_listening(self):
        self.is_listening = True
        self.retrieve_latest_conversation()
        self.timer = self.frame.after(int(ApplicationState.retrieval_speed * 1000), self.retrieve_messages_from_conversation)

    def stop_listening(self):
        if self.timer:
            self.frame.after_cancel(self.timer)
        self.is_listening = False

    def retrieve_latest_conversation(self):
        if ApplicationState.auth_token == "":
            self.log_error("No OpenAI auth token found: please set one in settings")
            return

        url = "https://chatgpt.com/backend-api/conversations?offset=0&limit=1&order=updated"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ApplicationState.auth_token}",
        }

        response = requests.get(url, headers=headers)
        if response.status_code == 401:
            self.log_error("Unauthorized")
            return

        conversation_history = response.json()
        if conversation_history['items']:
            first_item = conversation_history['items'][0]
            utc_time = time.strptime(first_item['update_time'], "%Y-%m-%dT%H:%M:%S.%fZ")
            current_time_utc = time.gmtime()
            if time.mktime(current_time_utc) - time.mktime(utc_time) > ApplicationState.latest_conversation_cutoff:
                print("Conversation is too old")
            else:
                self.conversation_id = first_item['id']
                self.retrieve_messages_from_conversation()

    def retrieve_messages_from_conversation(self):
        if ApplicationState.auth_token == "":
            print("No OpenAI key found")
            return

        url = f"https://chatgpt.com/backend-api/conversation/{self.conversation_id}"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ApplicationState.auth_token}",
        }

        response = requests.get(url, headers=headers)
        if response.status_code == 401:
            self.log_error("Unauthorized")
            return

        message = response.json()
        self.update_messages(message)

        if self.is_listening:
            self.timer = self.frame.after(int(ApplicationState.retrieval_speed * 1000), self.retrieve_messages_from_conversation)

    def update_messages(self, message):
        self.text_area.config(state='normal')
        self.text_area.delete(1.0, tk.END)

        for item in message['mapping'].values():
            message_id = item['message']['id']
            author = item['message']['author']
            content = item['message']['content']['parts'][0]

            if author['role'] != 'system' and message_id not in self.message_ids:
                is_user = author['role'] == 'user'
                self.messages.append({
                    'text': content,
                    'is_user': is_user,
                    'id': message_id,
                    'create_time': item['message']['create_time'],
                    'translation': 'loading...'
                })
                self.message_ids.append(message_id)

        for msg in self.messages:
            self.text_area.insert(tk.END, f"{msg['text']}\n", 'user' if msg['is_user'] else 'oai')

        self.text_area.config(state='disabled')

    def clear_conversation(self):
        self.messages = []
        self.conversation_id = ""
        self.conversation_title = ""
        self.text_area.config(state='normal')
        self.text_area.delete(1.0, tk.END)
        self.text_area.config(state='disabled')

    def log_error(self, error_text):
        print(f"Error: {error_text}")
        messagebox.showerror("Error", error_text)
        self.stop_listening()
