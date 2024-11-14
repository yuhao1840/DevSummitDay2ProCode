import streamlit as st  
from style import global_page_style2
import time
import os
from dotenv import load_dotenv
import requests
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential
from openai import AzureOpenAI
import base64

load_dotenv()

AZURE_OPENAI_ACCOUNT: str                                               = os.environ["AZURE_OPENAI_API_INSTANCE_NAME"]
AZURE_DEPLOYMENT_MODEL: str                                             = os.environ["AZURE_OPEN_AI_DEPLOYMENT_MODEL"]
AZURE_OPENAI_KEY: str                                                   = os.environ["AZURE_OPENAI_API_KEY"]
service_endpoint                                                        = os.environ["AZURE_SEARCH_NAME"]
index_name                                                              = os.environ["AZURE_SEARCH_INDEX_NAME"]
key                                                                     = os.environ["AZURE_SEARCH_API_KEY"]
api_version                                                             = os.environ["AZURE_OPENAI_API_VERSION"]

search_client                                                           = SearchClient(service_endpoint, index_name, AzureKeyCredential(key))

def chat(messages, question):  
    #messages.append({"role": "user", "content": "👤: " + question})  
    messages.append({"role": "user", "content":question})  
    with st.chat_message("user", avatar="👤"):  
        st.markdown(question)  
    with st.spinner('Processing...'): 
        #time.sleep(5) 
        # messages.append({"role": "assistant", "content": "🤖: " + question})  

        GROUNDED_PROMPT="""
        You are a friendly assistant that answers questions about ice cream.
        answer the question with only the informaion provided in the sources.
        If there isn't enough information below, say you don't know.
        Do not generate answers that don't use the sources below.      
        Sources:\n{sources}   
        """

        search_results = search_client.search(
            search_text=question,
            top=5,
            select="chunk"
        )
        sources_formatted = "\n".join([f'{document["chunk"]}' for document in search_results])

        client = AzureOpenAI(
            api_key=AZURE_OPENAI_KEY,  
            api_version=api_version,
            azure_endpoint=AZURE_OPENAI_ACCOUNT)

        print(GROUNDED_PROMPT.format(sources=sources_formatted))

        #st.text(GROUNDED_PROMPT.format(sources=sources_formatted))

        chat_completion = client.chat.completions.create(
        model=AZURE_DEPLOYMENT_MODEL,
        
        messages=[
        {
            "role": "system",
            "content": [
                {
                    "type": "text",
                    "text": GROUNDED_PROMPT.format(sources=sources_formatted)
                }
            ]
        },
        {
            "role": "user",
            "content": question
        }
    ],
    temperature=0.7,
    top_p=0.5
    )

    print(chat_completion.choices[0].message.content)

    messages.append({"role": "assistant", "content":chat_completion.choices[0].message.content})  
    with st.chat_message("assistant", avatar="🤖"):  
        st.markdown(chat_completion.choices[0].message.content)  
  
def clear_session(messages):  
    # Clear necessary session state variables  
    st.cache_data.clear()  
    messages.clear()  
    return messages  

# Function to get the image as a base64 string  
def get_base64_of_bin_file(bin_file):  
    with open(bin_file, 'rb') as f:  
        data = f.read()  
    return base64.b64encode(data).decode()  
  
def main():  
    st.write("<br>", unsafe_allow_html=True)  
    #st.write("m_strVaultURL:" + m_strVaultURL)
    # st.title("Ice Cream Bot")  
    # st.sidebar.title("Azure OpenAI Parameters")
    # st.write("-"*50)
    # clear_chat_placeholder = st.empty()  
      
    if 'messages' not in st.session_state:  
        st.session_state.messages = []  

    question = st.chat_input('Ask your ice cream question here... ')  
  
    avatars = {  
        "assistant": "🤖",  # Avatar for assistant  
        "user": "👤"        # Avatar for user  
    }  

    for message in st.session_state.messages:  
        avatar = avatars.get(message["role"], "❓")  # Get the avatar based on the role  
        with st.chat_message(message["role"], avatar=avatar):  
            st.markdown(message['content'])  
   
    # question = st.chat_input('Ask your ice cream question here... ')  
    if question:  
        chat(st.session_state.messages, question)  
        st.write('-'*50)
    clear_chat_placeholder = st.empty()  
    if clear_chat_placeholder.button('Start New Session'):  
        st.session_state.messages = clear_session(st.session_state.messages)  
        clear_chat_placeholder.empty()  
        st.success("Ice Cream Bot session has been reset.")  
  
if __name__ == '__main__':  
    global_page_style2()  
    # Path to the image  
    image_path = "./images/ice_cream_logo2.png"  
    # Get the base64 string of the image  
    img_base64 = get_base64_of_bin_file(image_path)  
    
    # Generate the HTML content with the local image and the title  
    html_content = f'''  
    <div style="display: flex; justify-content: center; align-items: center;">  
        <div style="flex-shrink: 0;">  
            <img src="data:image/png;base64,{img_base64}" width="150">  
        </div>  
        <div style="margin-left: 20px;">  
            <h1 style="margin: 0;">Ice Cream Bot</h1>  
        </div>  
    </div>  
    '''  
    
    # Display the image and title using st.markdown  
    st.markdown(html_content, unsafe_allow_html=True)  
    st.sidebar.title("Azure OpenAI Parameters")
    main()  
