import React, { useState, useEffect, useMemo, useRef } from 'react';
import { 
  Search, Menu, X, Moon, Sun, Star, ExternalLink, 
  Filter, Zap, Video, Mic, Music, Code, BookOpen, 
  Image as ImageIcon, Share2, Heart, History, User,
  TrendingUp, Sparkles, LayoutGrid, MessageSquare, Send, Bot, Loader2
} from 'lucide-react';

// --- GEMINI API UTILITIES ---
const apiKey = ""; AIzaSyAdn05aCTMm-k1gfBVGqitIUe_I2jSRV70

// callGemini: साधारण POST wrapper (यदि apiKey खाली है तो mock response देगा)
const callGemini = async (prompt, systemInstruction = "") => {
  if (!apiKey) {
    // mock response when API key not set
    return `💡 (Mock) सुझाव: Try using ChatGPT or Gemini for "${prompt}".`;
  }
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${apiKey}`;
  const payload = {
    contents: [{ parts: [{ text: prompt }] }],
    systemInstruction: { parts: [{ text: systemInstruction }] }
  };

  const delays = [1000, 2000, 4000, 8000, 16000];
  for (let i = 0; i <= delays.length; i++) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      const data = await response.json();
      return data.candidates?.[0]?.content?.parts?.[0]?.text || "Sorry, I couldn't generate a response.";
    } catch (error) {
      if (i === delays.length) return "Error: Unable to connect to AI service. Please try again later.";
      await new Promise(resolve => setTimeout(resolve, delays[i]));
    }
  }
};

// --- MOCK DATA ---
const CATEGORIES = [
  { id: 'all', name: 'All Tools', icon: LayoutGrid },
  { id: 'video', name: 'Text-to-Video', icon: Video },
  { id: 'voice', name: 'Text-to-Voice', icon: Mic },
  { id: 'image', name: 'Image Gen', icon: ImageIcon },
  { id: 'coding', name: 'Coding AI', icon: Code },
  { id: 'music', name: 'Music AI', icon: Music },
  { id: 'study', name: 'Study & Notes', icon: BookOpen },
  { id: 'chat', name: 'ChatBots', icon: Sparkles },
];

const TOOLS_DATA = [
  { id:1, name:'ChatGPT', category:'chat', description:'The industry standard conversational AI model by OpenAI. Great for writing, coding, and general assistance.', detailedDesc:'ChatGPT is an AI chatbot...', url:'https://chat.openai.com', image:'https://upload.wikimedia.org/wikipedia/commons/0/04/ChatGPT_logo.svg', isFree:true, rating:4.9, isTrending:true, isNew:false },
  { id:2, name:'Suno AI', category:'music', description:'Create realistic songs and music from simple text prompts.', detailedDesc:'Suno AI allows users to generate hyper-realistic songs...', url:'https://www.suno.ai', image:'https://pbs.twimg.com/profile_images/1737527668102176768/Cj_GqOmS_400x400.jpg', isFree:false, rating:4.8, isTrending:true, isNew:true },
  { id:3, name:'RunwayML', category:'video', description:'Professional grade AI video editing and generation tools.', detailedDesc:'Runway offers a suite of AI magic tools...', url:'https://runwayml.com', image:'https://yt3.googleusercontent.com/ytc/AIdro_kK15tJ9x0hZgD_y_aRj_1e4_k_X_1_1_1=s900-c-k-c0x00ffffff-no-rj', isFree:false, rating:4.7, isTrending:true, isNew:false },
  { id:4, name:'Midjourney', category:'image', description:'Generates hyper-realistic images from text descriptions.', detailedDesc:'Known for its artistic style...', url:'https://www.midjourney.com', image:'https://upload.wikimedia.org/wikipedia/commons/e/ed/Midjourney_Emblem.png', isFree:false, rating:4.9, isTrending:true, isNew:false },
  { id:5, name:'ElevenLabs', category:'voice', description:'The most realistic text-to-speech and voice cloning AI.', detailedDesc:'ElevenLabs offers industry-leading voice synthesis...', url:'https://elevenlabs.io', image:'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT7_1_1_1_1_1_1_1_1_1_1_1_1_1_1&s', isFree:false, rating:4.8, isTrending:true, isNew:false },
  { id:6, name:'Blackbox AI', category:'coding', description:'AI coding assistant optimized for developers and students.', detailedDesc:'Blackbox helps you write code faster...', url:'https://www.blackbox.ai', image:'https://pbs.twimg.com/profile_images/1632766324888805377/1_1_1_1_400x400.jpg', isFree:true, rating:4.6, isTrending:false, isNew:true },
  { id:7, name:'Photomath', category:'study', description:'Scan math problems and get step-by-step solutions.', detailedDesc:'Perfect for students...', url:'https://photomath.com', image:'https://play-lh.googleusercontent.com/1_1_1_1_1_1_1_1_1_1_1_1_1_1_1=w240-h480-rw', isFree:true, rating:4.7, isTrending:false, isNew:false },
  { id:8, name:'Gemini', category:'chat', description:"Google's most capable AI model, integrated with Google apps.", detailedDesc:"Gemini (formerly Bard) is Google's conversational AI...", url:'https://gemini.google.com', image:'https://upload.wikimedia.org/wikipedia/commons/8/8a/Google_Gemini_logo.svg', isFree:true, rating:4.6, isTrending:true, isNew:true },
  { id:9, name:'Leonardo AI', category:'image', description:'Create production-quality visual assets for your projects.', detailedDesc:'Leonardo AI is designed for game developers...', url:'https://leonardo.ai', image:'https://pbs.twimg.com/profile_images/1_1_1_1_1_1_1_1_1_1_1_1/1_1_1_1_400x400.jpg', isFree:true, rating:4.7, isTrending:true, isNew:true },
  { id:10, name:'Voicemod', category:'voice', description:'Real-time voice changer and soundboard.', detailedDesc:'Transform your voice in real-time...', url:'https://www.voicemod.net', image:'https://pbs.twimg.com/profile_images/1_1_1_1_1_1_1_1_1_1_1_1/1_1_1_1_400x400.jpg', isFree:true, rating:4.5, isTrending:false, isNew:false },
  { id:11, name:'Khanmigo', category:'study', description:"Khan Academy's AI tutor for students and teachers.", detailedDesc:'Khanmigo guides students...', url:'https://www.khanacademy.org/khanmigo', image:'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Khan_Academy_Logo_2018.svg/1200px-Khan_Academy_Logo_2018.svg.png', isFree:false, rating:4.8, isTrending:false, isNew:true },
  { id:12, name:'GitHub Copilot', category:'coding', description:'Your AI pair programmer.', detailedDesc:'Copilot suggests code...', url:'https://github.com/features/copilot', image:'https://upload.wikimedia.org/wikipedia/commons/2/29/GitHub_Copilot_logo.svg', isFree:false, rating:4.9, isTrending:true, isNew:false }
];

// --- COMPONENTS ---
const Header = ({ darkMode, setDarkMode, toggleSidebar, activeSection, setActiveSection }) => (
  <header className={`sticky top-0 z-50 backdrop-blur-lg border-b ${darkMode ? 'bg-slate-900/80 border-slate-700' : 'bg-white/80 border-gray-200'}`}>
    <div className="container mx-auto px-4 h-16 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <button onClick={toggleSidebar} className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-slate-800 transition-colors">
          <Menu className={darkMode ? 'text-white' : 'text-gray-800'} size={24} />
        </button>
        <div className="flex items-center gap-2 cursor-pointer" onClick={() => setActiveSection('home')}>
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
            <Sparkles className="text-white" size={18} />
          </div>
          <span className={`text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r ${darkMode ? 'from-white to-gray-400' : 'from-gray-900 to-gray-600'}`}>
            Adda of AI
          </span>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button 
          onClick={() => setActiveSection('favorites')}
          className={`p-2 rounded-full transition-all ${activeSection === 'favorites' ? 'bg-red-500/10 text-red-500' : 'hover:bg-gray-100 dark:hover:bg-slate-800 text-gray-500'}`}
        >
          <Heart size={20} fill={activeSection === 'favorites' ? "currentColor" : "none"} />
        </button>
        <button 
          onClick={() => setDarkMode(!darkMode)}
          className={`p-2 rounded-full transition-all hover:bg-gray-100 dark:hover:bg-slate-800 ${darkMode ? 'text-yellow-400' : 'text-slate-600'}`}
        >
          {darkMode ? <Sun size={20} /> : <Moon size={20} />}
        </button>
        <button className="hidden sm:flex items-center gap-2 px-4 py-2 rounded-full bg-blue-600 hover:bg-blue-700 text-white font-medium transition-all text-sm">
          <User size={16} />
          Login
        </button>
      </div>
    </div>
  </header>
);

const Sidebar = ({ isOpen, closeSidebar, activeCategory, setActiveCategory, darkMode, categories }) => (
  <>
    {isOpen && (
      <div className="fixed inset-0 bg-black/50 z-40 lg:hidden backdrop-blur-sm" onClick={closeSidebar} />
    )}
    <aside className={`fixed top-16 left-0 h-[calc(100vh-64px)] w-64 z-40 transform transition-transform duration-300 ease-in-out lg:translate-x-0 ${isOpen ? 'translate-x-0' : '-translate-x-full'} ${darkMode ? 'bg-slate-900 border-r border-slate-700' : 'bg-white border-r border-gray-200'} overflow-y-auto`}>
      <div className="p-4 space-y-6">
        <div>
          <h3 className={`text-xs font-semibold uppercase tracking-wider mb-4 ${darkMode ? 'text-slate-400' : 'text-gray-500'}`}>
            Categories
          </h3>
          <div className="space-y-1">
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => {
                  setActiveCategory(cat.id);
                  if (window.innerWidth < 1024) closeSidebar();
                }}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                  activeCategory === cat.id
                    ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20'
                    : `hover:bg-gray-100 dark:hover:bg-slate-800 ${darkMode ? 'text-slate-300' : 'text-gray-600'}`
                }`}
              >
                <cat.icon size={18} />
                {cat.name}
              </button>
            ))}
          </div>
        </div>

        <div className={`p-4 rounded-xl border ${darkMode ? 'bg-slate-800/50 border-slate-700' : 'bg-gray-50 border-gray-200'}`}>
          <div className="flex items-center gap-2 mb-2">
            <Zap className="text-yellow-500" size={16} />
            <span className={`text-xs font-bold ${darkMode ? 'text-white' : 'text-gray-900'}`}>Featured</span>
          </div>
          <p className={`text-xs mb-3 ${darkMode ? 'text-slate-400' : 'text-gray-500'}`}>
            Upgrade your workflow with AI Tools Pro.
          </p>
          <button className="w-full py-1.5 text-xs font-semibold text-blue-600 bg-blue-500/10 rounded-lg hover:bg-blue-500/20 transition-colors">
            Learn More
          </button>
        </div>
      </div>
    </aside>
  </>
);

const ToolCard = ({ tool, darkMode, onClick, isFavorite, toggleFavorite }) => (
  <div 
    className={`group relative rounded-xl border transition-all duration-300 hover:-translate-y-1 hover:shadow-xl cursor-pointer
      ${darkMode ? 'bg-slate-800 border-slate-700 hover:shadow-blue-500/10' : 'bg-white border-gray-200 hover:shadow-gray-200'}`}
    onClick={() => onClick(tool)}
  >
    <div className="absolute top-3 right-3 flex gap-2">
       {tool.isTrending && (
        <span className="flex items-center gap-1 px-2 py-1 rounded-full bg-orange-500/10 text-orange-500 text-[10px] font-bold uppercase tracking-wider border border-orange-500/20">
          <TrendingUp size={10} /> Trending
        </span>
      )}
      <button 
        onClick={(e) => {
          e.stopPropagation();
          toggleFavorite(tool.id);
        }}
        className={`p-1.5 rounded-full backdrop-blur-sm transition-colors ${
          isFavorite 
            ? 'bg-red-500/10 text-red-500' 
            : `bg-black/5 ${darkMode ? 'text-slate-400 hover:text-white' : 'text-gray-400 hover:text-gray-900'}`
        }`}
      >
        <Heart size={14} fill={isFavorite ? "currentColor" : "none"} />
      </button>
    </div>

    <div className="p-5">
      <div className="flex items-start gap-4 mb-4">
        <div className={`w-12 h-12 rounded-xl overflow-hidden flex-shrink-0 ${darkMode ? 'bg-slate-700' : 'bg-gray-100'}`}>
             <img src={tool.image} alt={tool.name} className="w-full h-full object-cover" onError={(e) => {e.target.src='https://placehold.co/100x100?text=AI'}} />
        </div>
        <div>
          <h3 className={`font-bold text-lg mb-1 ${darkMode ? 'text-white' : 'text-gray-900'}`}>{tool.name}</h3>
          <div className="flex items-center gap-2">
            <span className={`text-xs px-2 py-0.5 rounded-md font-medium ${tool.isFree ? 'bg-green-500/10 text-green-600' : 'bg-purple-500/10 text-purple-600'}`}>
              {tool.isFree ? 'Free' : 'Paid'}
            </span>
            <div className="flex items-center gap-1 text-yellow-500 text-xs font-bold">
              <Star size={10} fill="currentColor" />
              {tool.rating}
            </div>
          </div>
        </div>
      </div>
      
      <p className={`text-sm line-clamp-2 mb-4 ${darkMode ? 'text-slate-400' : 'text-gray-600'}`}>
        {tool.description}
      </p>
      
      <div className={`pt-4 border-t flex items-center justify-between text-xs font-medium ${darkMode ? 'border-slate-700 text-slate-500' : 'border-gray-100 text-gray-500'}`}>
        <span className="flex items-center gap-1">
          <Share2 size={12} /> Share
        </span>
        <span className="flex items-center gap-1 group-hover:text-blue-500 transition-colors">
          View Details <ExternalLink size={12} />
        </span>
      </div>
    </div>
  </div>
);

const AIChatBot = ({ isOpen, onClose, darkMode }) => {
  const [messages, setMessages] = useState([
    { role: 'model', text: 'Hi! I\\'m your AI Guide. Tell me what you want to create (e.g., \"music video\", \"study notes\"), and I\\'ll recommend the best tools!' }
  ]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isOpen]);

  const handleSend = async () => {
    if (!inputText.trim()) return;
    
    const userMsg = { role: 'user', text: inputText };
    setMessages(prev => [...prev, userMsg]);
    setInputText('');
    setIsLoading(true);

    const toolsContext = TOOLS_DATA.map(t => `- ${t.name} (${t.category}): ${t.description}`).join('\\n');
    const systemPrompt = `You are a helpful assistant for an AI Tools Directory. 
    Here is a list of available tools: 
    ${toolsContext}
    
    The user will ask for help finding a tool or how to do a task. 
    Recommend specific tools from the list if applicable, or give general advice if no tool fits perfectly. 
    Keep answers short, friendly, and helpful. Use emojis.`;

    const responseText = await callGemini(inputText, systemPrompt);
    
    setMessages(prev => [...prev, { role: 'model', text: responseText }]);
    setIsLoading(false);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed bottom-20 right-4 sm:right-8 z-50 w-[90vw] sm:w-96 h-[500px] shadow-2xl rounded-2xl flex flex-col overflow-hidden border animate-in slide-in-from-bottom-10 fade-in duration-300 bg-white dark:bg-slate-900 border-gray-200 dark:border-slate-700">
      <div className="p-4 bg-gradient-to-r from-blue-600 to-purple-600 flex justify-between items-center text-white">
        <div className="flex items-center gap-2">
          <Bot size={20} />
          <span className="font-bold">AI Concierge</span>
        </div>
        <button onClick={onClose} className="p-1 hover:bg-white/20 rounded-full transition-colors">
          <X size={18} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50 dark:bg-slate-950">
        {messages.map((msg, idx) => (
          <div key={idx} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] p-3 rounded-2xl text-sm ${
              msg.role === 'user' 
                ? 'bg-blue-600 text-white rounded-br-none' 
                : 'bg-white dark:bg-slate-800 border border-gray-200 dark:border-slate-700 text-gray-800 dark:text-gray-200 rounded-bl-none shadow-sm'
            }`}>
              {msg.text}
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-white dark:bg-slate-800 p-3 rounded-2xl rounded-bl-none border border-gray-200 dark:border-slate-700 shadow-sm">
              <Loader2 size={16} className="animate-spin text-blue-500" />
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="p-3 bg-white dark:bg-slate-900 border-t border-gray-200 dark:border-slate-700">
        <div className="flex items-center gap-2">
          <input
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Ask for a tool recommendation..."
            className="flex-1 bg-gray-100 dark:bg-slate-800 border-none rounded-full px-4 py-2 text-sm focus:ring-2 focus:ring-blue-500 dark:text-white"
          />
          <button 
            onClick={handleSend}
            disabled={isLoading || !inputText.trim()}
            className="p-2 bg-blue-600 text-white rounded-full hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};

const ToolModal = ({ tool, isOpen, onClose, darkMode }) => {
  const [ideas, setIdeas] = useState(null);
  const [isGenerating, setIsGenerating] = useState(false);

  useEffect(() => {
    if (!isOpen) setIdeas(null); // Reset when closed
  }, [isOpen]);

  const generateIdeas = async () => {
    setIsGenerating(true);
    const prompt = `Suggest 3 creative, distinct, and specific use cases for an AI tool named '${tool.name}' which is described as: '${tool.detailedDesc}'. 
    Format the response as a simple list of 3 bullet points starting with emojis. Do not include introductory text.`;
    
    const response = await callGemini(prompt);
    setIdeas(response);
    setIsGenerating(false);
  };

  if (!isOpen || !tool) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative w-full max-w-2xl max-h-[90vh] overflow-y-auto rounded-2xl shadow-2xl animate-in fade-in zoom-in duration-200 ${darkMode ? 'bg-slate-900 text-white' : 'bg-white text-gray-900'}`}>
        
        <div className="relative h-32 bg-gradient-to-r from-blue-600 to-purple-600 p-6 flex items-end">
          <button 
            onClick={onClose}
            className="absolute top-4 right-4 p-2 rounded-full bg-black/20 text-white hover:bg-black/40 transition-colors"
          >
            <X size={20} />
          </button>
          <div className="flex items-end gap-4 translate-y-8">
            <div className={`w-24 h-24 rounded-2xl shadow-lg overflow-hidden border-4 ${darkMode ? 'border-slate-900 bg-slate-800' : 'border-white bg-white'}`}>
                <img src={tool.image} alt={tool.name} className="w-full h-full object-cover" onError={(e) => {e.target.src='https://placehold.co/100x100?text=AI'}} />
            </div>
            <div className="mb-2">
              <h2 className="text-2xl font-bold text-white shadow-black/20 drop-shadow-md">{tool.name}</h2>
              <span className="text-blue-100 text-sm font-medium opacity-90">{CATEGORIES.find(c => c.id === tool.category)?.name}</span>
            </div>
          </div>
        </div>

        <div className="pt-12 px-6 pb-8">
          <div className="flex flex-wrap gap-3 mb-6">
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${tool.isFree ? 'bg-green-100 text-green-700' : 'bg-purple-100 text-purple-700'}`}>
              {tool.isFree ? 'Free to use' : 'Paid / Premium'}
            </span>
             {tool.isTrending && <span className="px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-700">Trending 🔥</span>}
             {tool.isNew && <span className="px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-700">New Arrival</span>}
          </div>

          <div className="space-y-6 mb-8">
            <div>
              <h3 className="text-lg font-semibold mb-2">About this Tool</h3>
              <p className={`leading-relaxed ${darkMode ? 'text-slate-300' : 'text-gray-600'}`}>
                {tool.detailedDesc}
              </p>
            </div>

            <div className={`p-5 rounded-xl border ${darkMode ? 'bg-slate-800 border-slate-700' : 'bg-blue-50 border-blue-100'}`}>
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold flex items-center gap-2">
                  <Sparkles size={18} className="text-blue-500" />
                  AI Inspiration
                </h3>
                {!ideas && (
                  <button 
                    onClick={generateIdeas}
                    disabled={isGenerating}
                    className="text-xs bg-blue-600 text-white px-3 py-1.5 rounded-full hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center gap-1"
                  >
                    {isGenerating ? <Loader2 size={12} className="animate-spin" /> : '✨ Generate Ideas'}
                  </button>
                )}
              </div>
              
              {isGenerating && (
                <div className="py-4 text-center text-sm text-gray-500 animate-pulse">
                  Brainstorming cool ideas for you...
                </div>
              )}

              {ideas && (
                <div className={`text-sm leading-relaxed whitespace-pre-line ${darkMode ? 'text-slate-300' : 'text-gray-700'}`}>
                  {ideas}
                </div>
              )}
              
              {!ideas && !isGenerating && (
                <p className={`text-sm ${darkMode ? 'text-slate-400' : 'text-gray-500'}`}>
                  Not sure what to create? Let Gemini suggest 3 creative use cases for {tool.name}.
                </p>
              )}
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div className={`p-4 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-gray-50'}`}>
                <div className="text-sm text-gray-500 mb-1">Rating</div>
                <div className="text-xl font-bold flex items-center gap-1">
                  {tool.rating} <Star size={16} className="text-yellow-500 fill-yellow-500" />
                </div>
              </div>
              <div className={`p-4 rounded-xl ${darkMode ? 'bg-slate-800' : 'bg-gray-50'}`}>
                <div className="text-sm text-gray-500 mb-1">Language</div>
                <div className="text-xl font-bold">English + 50</div>
              </div>
            </div>
          </div>

          <a 
            href={tool.url}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full flex items-center justify-center gap-2 py-4 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-lg transition-all transform active:scale-95 shadow-lg shadow-blue-500/25"
          >
            Visit Official Website <ExternalLink size={20} />
          </a>
        </div>
      </div>
    </div>
  );
};

const App = () => {
  const [darkMode, setDarkMode] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [activeCategory, setActiveCategory] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState('all'); // all, free, paid, trending
  const [selectedTool, setSelectedTool] = useState(null);
  const [favorites, setFavorites] = useState([]);
  const [history, setHistory] = useState([]);
  const [activeSection, setActiveSection] = useState('home'); // home, favorites
  const [isChatOpen, setIsChatOpen] = useState(false); // New state for chat

  useEffect(() => {
    const savedFavs = JSON.parse(localStorage.getItem('ai-tools-favorites') || '[]');
    setFavorites(savedFavs);
    const savedHist = JSON.parse(localStorage.getItem('ai-tools-history') || '[]');
    setHistory(savedHist);
  }, []);

  useEffect(() => {
    localStorage.setItem('ai-tools-favorites', JSON.stringify(favorites));
  }, [favorites]);

  const toggleFavorite = (toolId) => {
    setFavorites(prev => 
      prev.includes(toolId) ? prev.filter(id => id !== toolId) : [...prev, toolId]
    );
  };

  const handleToolClick = (tool) => {
    setSelectedTool(tool);
    const newHistory = [tool.id, ...history.filter(id => id !== tool.id)].slice(0, 10);
    setHistory(newHistory);
    localStorage.setItem('ai-tools-history', JSON.stringify(newHistory));
  };

  const filteredTools = useMemo(() => {
    let tools = TOOLS_DATA;

    if (activeSection === 'favorites') {
      tools = tools.filter(t => favorites.includes(t.id));
    }

    if (activeCategory !== 'all' && activeSection !== 'favorites') {
      tools = tools.filter(t => t.category === activeCategory);
    }

    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      tools = tools.filter(t => 
        t.name.toLowerCase().includes(q) || 
        t.description.toLowerCase().includes(q) ||
        t.category.toLowerCase().includes(q)
      );
    }

    if (filterType === 'free') {
      tools = tools.filter(t => t.isFree);
    } else if (filterType === 'paid') {
      tools = tools.filter(t => !t.isFree);
    } else if (filterType === 'trending') {
      tools = tools.filter(t => t.isTrending);
    }

    return tools;
  }, [activeCategory, searchQuery, filterType, activeSection, favorites, history]);

  return (
    <div className={`min-h-screen font-sans transition-colors duration-300 ${darkMode ? 'bg-slate-950 text-slate-100' : 'bg-gray-50 text-gray-900'}`}>
      
      <Header 
        darkMode={darkMode} 
        setDarkMode={setDarkMode} 
        toggleSidebar={() => setIsSidebarOpen(!isSidebarOpen)}
        activeSection={activeSection}
        setActiveSection={setActiveSection}
      />

      <Sidebar 
        isOpen={isSidebarOpen} 
        closeSidebar={() => setIsSidebarOpen(false)}
        activeCategory={activeCategory}
        setActiveCategory={setActiveCategory}
        darkMode={darkMode}
        categories={CATEGORIES}
      />

      <main className={`transition-all duration-300 lg:ml-64 p-4 lg:p-8 pt-20 lg:pt-8`}>
        
        {activeSection === 'home' && !searchQuery && (
          <div className="mb-10 text-center py-10 px-4">
            <h1 className="text-4xl md:text-5xl font-extrabold mb-4 tracking-tight">
              Discover the Best <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-500 to-purple-600">AI Tools</span>
            </h1>
            <p className={`text-lg max-w-2xl mx-auto mb-8 ${darkMode ? 'text-slate-400' : 'text-gray-500'}`}>
              The ultimate directory for Text-to-Video, Voice, Coding, and Study AI tools. Updated daily.
            </p>
            
            <div className="relative max-w-xl mx-auto group">
              <div className={`absolute inset-0 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl blur opacity-20 group-hover:opacity-30 transition-opacity`}></div>
              <div className={`relative flex items-center p-2 rounded-2xl border shadow-lg ${darkMode ? 'bg-slate-900 border-slate-700' : 'bg-white border-gray-200'}`}>
                <Search className={`ml-3 mr-2 ${darkMode ? 'text-slate-400' : 'text-gray-400'}`} size={20} />
                <input
                  type="text"
                  placeholder="Search Suno, ChatGPT, RunwayML..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className={`w-full bg-transparent border-none focus:ring-0 text-lg placeholder-opacity-50 ${darkMode ? 'text-white placeholder-slate-500' : 'text-gray-900 placeholder-gray-400'}`}
                />
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
          <h2 className="text-2xl font-bold flex items-center gap-2">
            {activeSection === 'favorites' ? (
              <>
                <Heart className="text-red-500" fill="currentColor" /> My Favorites
              </>
            ) : (
              <>
                {searchQuery ? 'Search Results' : CATEGORIES.find(c => c.id === activeCategory)?.name}
              </>
            )}
          </h2>

          {activeSection !== 'favorites' && (
            <div className="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0 no-scrollbar">
              {['all', 'free', 'paid', 'trending'].map((type) => (
                <button
                  key={type}
                  onClick={() => setFilterType(type)}
                  className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition-colors border ${
                    filterType === type 
                      ? 'bg-blue-600 border-blue-600 text-white' 
                      : `hover:bg-gray-100 dark:hover:bg-slate-800 ${darkMode ? 'border-slate-700 text-slate-300' : 'border-gray-200 text-gray-600'}`
                  }`}
                >
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                  {type === 'trending' && ' 🔥'}
                </button>
              ))}
            </div>
          )}
        </div>

        {filteredTools.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredTools.map(tool => (
              <ToolCard 
                key={tool.id} 
                tool={tool} 
                darkMode={darkMode} 
                onClick={handleToolClick}
                isFavorite={favorites.includes(tool.id)}
                toggleFavorite={toggleFavorite}
              />
            ))}
          </div>
        ) : (
          <div className="text-center py-20">
            <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 ${darkMode ? 'bg-slate-800 text-slate-500' : 'bg-gray-100 text-gray-400'}`}>
              <Search size={32} />
            </div>
            <h3 className={`text-xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-900'}`}>No tools found</h3>
            <p className={`${darkMode ? 'text-slate-400' : 'text-gray-500'}`}>Try adjusting your search or filters.</p>
          </div>
        )}

        <footer className={`mt-20 pt-10 border-t text-center pb-10 ${darkMode ? 'border-slate-800 text-slate-500' : 'border-gray-200 text-gray-500'}`}>
          <div className="flex justify-center gap-6 mb-4">
            <span className="cursor-pointer hover:text-blue-500">About Us</span>
            <span className="cursor-pointer hover:text-blue-500">Submit Tool</span>
            <span className="cursor-pointer hover:text-blue-500">Privacy</span>
            <span className="cursor-pointer hover:text-blue-500">Contact</span>
          </div>
          <p>© 2025 Adda of AI. All rights reserved.</p>
        </footer>
      </main>
      
      {!isChatOpen && (
        <button 
          onClick={() => setIsChatOpen(true)}
          className="fixed bottom-6 right-6 p-4 rounded-full bg-blue-600 text-white shadow-xl hover:bg-blue-700 hover:scale-105 transition-all z-40"
        >
          <MessageSquare size={24} fill="currentColor" />
        </button>
      )}

      <AIChatBot isOpen={isChatOpen} onClose={() => setIsChatOpen(false)} darkMode={darkMode} />

      <ToolModal 
        tool={selectedTool} 
        isOpen={!!selectedTool} 
        onClose={() => setSelectedTool(null)} 
        darkMode={darkMode} 
      />
    </div>
  );
};

export default App;
