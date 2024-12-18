import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import requests
import json
import time
from threading import Thread
from application_state import ApplicationState
from content_view import ContentView
from settings import Settings

class VoiceModeChatApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Voice Mode Chat")
        self.root.geometry("800x600")

        self.notebook = ttk.Notebook(root)
        self.notebook.pack(expand=True, fill='both')

        self.content_view = ContentView(self.notebook)
        self.settings_view = Settings(self.notebook)

        self.notebook.add(self.content_view.frame, text='Conversation')
        self.notebook.add(self.settings_view.frame, text='Settings')

        self.is_listening = False
        self.timer = None

    def toggle_listening(self):
        self.is_listening = not self.is_listening
        if self.is_listening:
            self.start_listening()
        else:
            self.stop_listening()

    def start_listening(self):
        self.is_listening = True
        self.retrieve_latest_conversation()
        self.timer = self.root.after(int(ApplicationState.retrieval_speed * 1000), self.retrieve_messages_from_conversation)

    def stop_listening(self):
        if self.timer:
            self.root.after_cancel(self.timer)
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
                self.content_view.conversation_id = first_item['id']
                self.retrieve_messages_from_conversation()

    def retrieve_messages_from_conversation(self):
        if ApplicationState.auth_token == "":
            print("No OpenAI key found")
            return

        url = f"https://chatgpt.com/backend-api/conversation/{self.content_view.conversation_id}"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ApplicationState.auth_token}",
        }

        response = requests.get(url, headers=headers)
        if response.status_code == 401:
            self.log_error("Unauthorized")
            return

        message = response.json()
        self.content_view.update_messages(message)

        if self.is_listening:
            self.timer = self.root.after(int(ApplicationState.retrieval_speed * 1000), self.retrieve_messages_from_conversation)

    def log_error(self, error_text):
        print(f"Error: {error_text}")
        messagebox.showerror("Error", error_text)
        self.stop_listening()

if __name__ == "__main__":
    root = tk.Tk()
    app = VoiceModeChatApp(root)
    root.mainloop()
