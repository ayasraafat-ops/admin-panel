'use client';

import { useChat } from 'ai/react';
import { Send, Bot, User, Loader2 } from 'lucide-react';
import { useEffect, useRef } from 'react';

export default function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  return (
    <div className="flex flex-col h-screen max-w-4xl mx-auto bg-gray-50 dark:bg-gray-900 shadow-xl overflow-hidden rounded-none sm:rounded-xl sm:my-8 sm:h-[calc(100vh-4rem)] border dark:border-gray-800">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 border-b dark:border-gray-700 p-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="bg-blue-600 p-2 rounded-lg">
            <Bot className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-xl text-gray-900 dark:text-white">Qwen 3.6 Plus Chat</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">Powered by OpenRouter AI</p>
          </div>
        </div>
      </header>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-6 bg-gray-50 dark:bg-gray-900">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center space-y-4">
            <div className="bg-blue-100 dark:bg-blue-900/30 p-4 rounded-full">
              <Bot className="w-12 h-12 text-blue-600 dark:text-blue-400" />
            </div>
            <div className="max-w-md text-gray-500 dark:text-gray-400">
              <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-2">Welcome!</h2>
              <p>I am an AI assistant powered by Qwen 3.6 Plus. How can I help you today?</p>
            </div>
          </div>
        ) : (
          messages.map((m) => (
            <div
              key={m.id}
              className={`flex gap-4 ${
                m.role === 'user' ? 'justify-end' : 'justify-start'
              }`}
            >
              {m.role === 'assistant' && (
                <div className="flex-shrink-0 mt-1">
                  <div className="bg-blue-600 p-2 rounded-full">
                    <Bot className="w-5 h-5 text-white" />
                  </div>
                </div>
              )}

              <div
                className={`max-w-[80%] rounded-2xl px-5 py-3 ${
                  m.role === 'user'
                    ? 'bg-blue-600 text-white rounded-br-none shadow-md'
                    : 'bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-bl-none shadow-sm border dark:border-gray-700'
                }`}
              >
                <div className="prose dark:prose-invert max-w-none break-words whitespace-pre-wrap">
                  {m.content}
                </div>
              </div>

              {m.role === 'user' && (
                <div className="flex-shrink-0 mt-1">
                  <div className="bg-gray-200 dark:bg-gray-700 p-2 rounded-full">
                    <User className="w-5 h-5 text-gray-600 dark:text-gray-300" />
                  </div>
                </div>
              )}
            </div>
          ))
        )}
        {isLoading && messages[messages.length - 1]?.role === 'user' && (
          <div className="flex gap-4 justify-start">
             <div className="flex-shrink-0 mt-1">
                <div className="bg-blue-600 p-2 rounded-full">
                  <Bot className="w-5 h-5 text-white" />
                </div>
              </div>
              <div className="bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-2xl rounded-bl-none shadow-sm border dark:border-gray-700 px-5 py-3 flex items-center gap-2">
                 <Loader2 className="w-4 h-4 animate-spin text-blue-600" />
                 <span className="text-sm">Thinking...</span>
              </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input Area */}
      <div className="bg-white dark:bg-gray-800 p-4 border-t dark:border-gray-700">
        <form onSubmit={handleSubmit} className="flex gap-3 relative max-w-4xl mx-auto">
          <input
            className="flex-1 p-4 rounded-xl border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-shadow pr-12"
            value={input}
            placeholder="Type your message..."
            onChange={handleInputChange}
            disabled={isLoading}
          />
          <button
            type="submit"
            disabled={isLoading || !input.trim()}
            className="absolute right-2 top-2 bottom-2 p-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center aspect-square"
          >
            <Send className="w-5 h-5" />
          </button>
        </form>
        <div className="text-center mt-3 text-xs text-gray-500">
          AI generated content may be inaccurate.
        </div>
      </div>
    </div>
  );
}
