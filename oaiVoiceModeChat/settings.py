import tkinter as tk
from tkinter import ttk
from application_state import ApplicationState

class Settings:
    def __init__(self, notebook):
        self.frame = ttk.Frame(notebook)
        self.setup_ui()

    def setup_ui(self):
        self.auth_token = tk.StringVar(value=ApplicationState.auth_token())
        self.retrieval_speed = tk.DoubleVar(value=ApplicationState.retrieval_speed())
        self.latest_conversation_cutoff = tk.DoubleVar(value=ApplicationState.latest_conversation_cutoff())
        self.selected_language = tk.StringVar(value=ApplicationState.selected_language())
        self.openai_api_key = tk.StringVar(value=ApplicationState.openai_api_key())

        ttk.Label(self.frame, text="Auth Token*").grid(row=0, column=0, sticky='w', padx=5, pady=5)
        ttk.Entry(self.frame, textvariable=self.auth_token, show='*').grid(row=0, column=1, padx=5, pady=5)
        ttk.Label(self.frame, text="OpenAI API Key (for Chinese learning)").grid(row=1, column=0, sticky='w', padx=5, pady=5)
        ttk.Entry(self.frame, textvariable=self.openai_api_key, show='*').grid(row=1, column=1, padx=5, pady=5)

        ttk.Label(self.frame, text="Language").grid(row=2, column=0, sticky='w', padx=5, pady=5)
        language_menu = ttk.OptionMenu(self.frame, self.selected_language, self.selected_language.get(), "en", "zh_CN", "zh_HK")
        language_menu.grid(row=2, column=1, padx=5, pady=5)

        ttk.Label(self.frame, text="Retrieval Speed").grid(row=3, column=0, sticky='w', padx=5, pady=5)
        ttk.Scale(self.frame, variable=self.retrieval_speed, from_=0.25, to=10, orient='horizontal').grid(row=3, column=1, padx=5, pady=5)
        ttk.Label(self.frame, textvariable=self.retrieval_speed).grid(row=3, column=2, padx=5, pady=5)

        ttk.Label(self.frame, text="Latest Conversation Cutoff").grid(row=4, column=0, sticky='w', padx=5, pady=5)
        ttk.Scale(self.frame, variable=self.latest_conversation_cutoff, from_=1, to=300, orient='horizontal').grid(row=4, column=1, padx=5, pady=5)
        ttk.Label(self.frame, textvariable=self.latest_conversation_cutoff).grid(row=4, column=2, padx=5, pady=5)

        ttk.Button(self.frame, text="Save", command=self.save_settings).grid(row=5, column=0, columnspan=3, pady=10)

    def save_settings(self):
        ApplicationState.set_auth_token(self.auth_token.get())
        ApplicationState.set_retrieval_speed(self.retrieval_speed.get())
        ApplicationState.set_latest_conversation_cutoff(self.latest_conversation_cutoff.get())
        ApplicationState.set_selected_language(self.selected_language.get())
        ApplicationState.set_openai_api_key(self.openai_api_key.get())
