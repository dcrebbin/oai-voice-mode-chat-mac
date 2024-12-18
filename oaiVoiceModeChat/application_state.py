import configparser

class ApplicationState:
    config = configparser.ConfigParser()
    config.read('settings.ini')

    @staticmethod
    def get_setting(section, setting, default_value):
        return ApplicationState.config.get(section, setting, fallback=default_value)

    @staticmethod
    def set_setting(section, setting, value):
        if not ApplicationState.config.has_section(section):
            ApplicationState.config.add_section(section)
        ApplicationState.config.set(section, setting, value)
        with open('settings.ini', 'w') as configfile:
            ApplicationState.config.write(configfile)

    @staticmethod
    def auth_token():
        return ApplicationState.get_setting('DEFAULT', 'authToken', '')

    @staticmethod
    def set_auth_token(value):
        ApplicationState.set_setting('DEFAULT', 'authToken', value)

    @staticmethod
    def retrieval_speed():
        return float(ApplicationState.get_setting('DEFAULT', 'retrievalSpeed', '3'))

    @staticmethod
    def set_retrieval_speed(value):
        ApplicationState.set_setting('DEFAULT', 'retrievalSpeed', str(value))

    @staticmethod
    def latest_conversation_cutoff():
        return float(ApplicationState.get_setting('DEFAULT', 'latestConversationCutoff', '30'))

    @staticmethod
    def set_latest_conversation_cutoff(value):
        ApplicationState.set_setting('DEFAULT', 'latestConversationCutoff', str(value))

    @staticmethod
    def selected_language():
        return ApplicationState.get_setting('DEFAULT', 'selectedLanguage', 'zh_CN')

    @staticmethod
    def set_selected_language(value):
        ApplicationState.set_setting('DEFAULT', 'selectedLanguage', value)

    @staticmethod
    def openai_api_key():
        return ApplicationState.get_setting('DEFAULT', 'openAiApiKey', '')

    @staticmethod
    def set_openai_api_key(value):
        ApplicationState.set_setting('DEFAULT', 'openAiApiKey', value)
