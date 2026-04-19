# Hero Section Templates

Ready-to-use hero section components in React + Tailwind CSS.

---

## 1. Gradient Background Hero

```jsx
function GradientHero() {
  return (
    <section className="relative min-h-[90vh] bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 overflow-hidden">
      {/* Background decoration */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-blue-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-purple-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>
      </div>
      
      <div className="relative container mx-auto px-6 py-24 lg:py-32">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          {/* Content */}
          <div className="space-y-8">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 rounded-full text-blue-700 text-sm font-medium">
              <span className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></span>
              Introducing v2.0
            </div>
            
            <h1 className="text-5xl lg:text-6xl xl:text-7xl font-bold text-slate-900 leading-[1.1] tracking-tight">
              Build better products,{' '}
              <span className="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                faster
              </span>
            </h1>
            
            <p className="text-xl text-slate-600 leading-relaxed max-w-xl">
              The all-in-one platform that helps teams collaborate seamlessly, 
              automate workflows, and ship products 10x faster.
            </p>
            
            <div className="flex flex-wrap gap-4">
              <button className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl shadow-lg shadow-blue-500/30 transition-all hover:shadow-xl hover:-translate-y-0.5">
                Start Free Trial
              </button>
              <button className="group px-8 py-4 bg-white hover:bg-slate-50 text-slate-700 font-semibold rounded-xl border border-slate-200 transition-all flex items-center gap-2">
                <svg className="w-5 h-5 text-slate-400 group-hover:text-blue-500 transition-colors" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" />
                </svg>
                Watch Demo
              </button>
            </div>
            
            {/* Social proof */}
            <div className="flex items-center gap-8 pt-8 border-t border-slate-200">
              <div className="flex -space-x-3">
                {[1,2,3,4,5].map(i => (
                  <div key={i} className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-indigo-500 border-2 border-white"></div>
                ))}
              </div>
              <div>
                <div className="flex items-center gap-1">
                  {[1,2,3,4,5].map(i => (
                    <svg key={i} className="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                  ))}
                </div>
                <p className="text-sm text-slate-600">
                  <span className="font-semibold text-slate-900">4.9/5</span> from 2,500+ reviews
                </p>
              </div>
            </div>
          </div>
          
          {/* Product visual */}
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-3xl blur-3xl opacity-20"></div>
            <div className="relative bg-white rounded-2xl shadow-2xl p-2 border border-slate-200">
              <div className="bg-slate-900 rounded-xl p-6">
                {/* Mock dashboard content */}
                <div className="space-y-4">
                  <div className="flex gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-500"></div>
                    <div className="w-3 h-3 rounded-full bg-yellow-500"></div>
                    <div className="w-3 h-3 rounded-full bg-green-500"></div>
                  </div>
                  <div className="h-48 bg-slate-800 rounded-lg"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

## 2. Dark Mode Hero

```jsx
function DarkHero() {
  return (
    <section className="relative min-h-screen bg-slate-950 overflow-hidden">
      {/* Gradient orbs */}
      <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500 rounded-full filter blur-[128px] opacity-20"></div>
      <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500 rounded-full filter blur-[128px] opacity-20"></div>
      
      {/* Grid pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:64px_64px]"></div>
      
      <div className="relative container mx-auto px-6 py-32 text-center">
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-slate-800 rounded-full text-slate-300 text-sm border border-slate-700">
            <span className="w-2 h-2 bg-emerald-400 rounded-full"></span>
            Now in public beta
          </div>
          
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white leading-[1.1] tracking-tight">
            Ship code{' '}
            <span className="bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              at the speed of thought
            </span>
          </h1>
          
          <p className="text-xl text-slate-400 max-w-2xl mx-auto leading-relaxed">
            The AI-powered development platform that helps you write, review, 
            and deploy code faster than ever before.
          </p>
          
          <div className="flex flex-wrap justify-center gap-4 pt-4">
            <button className="px-8 py-4 bg-white hover:bg-slate-100 text-slate-900 font-semibold rounded-xl transition-all">
              Get Started Free
            </button>
            <button className="px-8 py-4 bg-slate-800 hover:bg-slate-700 text-white font-semibold rounded-xl border border-slate-700 transition-all">
              View Documentation
            </button>
          </div>
          
          {/* Logo bar */}
          <div className="pt-16">
            <p className="text-sm text-slate-500 mb-8">Trusted by engineering teams at</p>
            <div className="flex flex-wrap justify-center items-center gap-x-12 gap-y-6 opacity-50">
              {['Vercel', 'Stripe', 'Linear', 'Notion', 'Figma'].map(name => (
                <span key={name} className="text-slate-400 font-semibold text-lg">{name}</span>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

## 3. Split Screen Hero

```jsx
function SplitHero() {
  return (
    <section className="min-h-screen flex flex-col lg:flex-row">
      {/* Content side */}
      <div className="flex-1 flex items-center justify-center p-8 lg:p-16 bg-white">
        <div className="max-w-lg space-y-8">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold">A</span>
            </div>
            <span className="font-semibold text-slate-900">Acme Analytics</span>
          </div>
          
          <h1 className="text-4xl lg:text-5xl font-bold text-slate-900 leading-tight">
            Turn data into decisions, instantly
          </h1>
          
          <p className="text-lg text-slate-600 leading-relaxed">
            Our AI-powered analytics platform helps you understand your customers, 
            predict trends, and make smarter business decisions.
          </p>
          
          <form className="space-y-4">
            <input 
              type="email" 
              placeholder="Enter your work email"
              className="w-full px-5 py-4 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <button className="w-full px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition-colors">
              Start 14-day free trial
            </button>
          </form>
          
          <p className="text-sm text-slate-500">
            No credit card required · Free 14-day trial · Cancel anytime
          </p>
        </div>
      </div>
      
      {/* Visual side */}
      <div className="flex-1 bg-gradient-to-br from-blue-600 to-indigo-700 p-8 lg:p-16 flex items-center justify-center">
        <div className="w-full max-w-lg bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
          {/* Mock chart */}
          <div className="space-y-4">
            <div className="flex justify-between items-center">
              <span className="text-white font-medium">Revenue Overview</span>
              <span className="text-white/60 text-sm">Last 30 days</span>
            </div>
            <div className="h-48 flex items-end gap-2">
              {[40, 65, 45, 80, 55, 90, 75].map((h, i) => (
                <div key={i} className="flex-1 bg-white/20 rounded-t" style={{height: `${h}%`}}></div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

## 4. Minimal Centered Hero

```jsx
function MinimalHero() {
  return (
    <section className="min-h-[80vh] flex items-center justify-center px-6 py-24 bg-white">
      <div className="max-w-3xl text-center space-y-8">
        <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-slate-900 leading-[1.1] tracking-tight">
          Simplify your workflow
        </h1>
        
        <p className="text-xl text-slate-600 max-w-xl mx-auto">
          One tool to manage your projects, team, and time. 
          No complexity, just results.
        </p>
        
        <div className="flex justify-center gap-4">
          <button className="px-8 py-4 bg-slate-900 hover:bg-slate-800 text-white font-semibold rounded-xl transition-colors">
            Get Started
          </button>
        </div>
        
        <p className="text-sm text-slate-400">
          Free forever · No credit card
        </p>
      </div>
    </section>
  );
}
```

---

## 5. Video Background Hero

```jsx
function VideoHero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Video background */}
      <div className="absolute inset-0">
        <video 
          autoPlay 
          muted 
          loop 
          playsInline
          className="w-full h-full object-cover"
        >
          <source src="/hero-video.mp4" type="video/mp4" />
        </video>
        <div className="absolute inset-0 bg-slate-900/70"></div>
      </div>
      
      {/* Content */}
      <div className="relative z-10 container mx-auto px-6 text-center">
        <div className="max-w-4xl mx-auto space-y-8">
          <h1 className="text-5xl md:text-6xl lg:text-7xl font-bold text-white leading-[1.1]">
            Experience the future of work
          </h1>
          
          <p className="text-xl text-slate-300 max-w-2xl mx-auto">
            Join thousands of teams who have transformed 
            how they collaborate and create.
          </p>
          
          <div className="flex flex-wrap justify-center gap-4">
            <button className="px-8 py-4 bg-white hover:bg-slate-100 text-slate-900 font-semibold rounded-xl transition-colors">
              Start Free Trial
            </button>
            <button className="group px-8 py-4 text-white font-semibold rounded-xl border border-white/30 hover:bg-white/10 transition-all flex items-center gap-2">
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" />
              </svg>
              Watch Video
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
```

---

## Animation CSS

Add to your global CSS:

```css
@keyframes blob {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(20px, -30px) scale(1.1); }
  50% { transform: translate(-20px, 20px) scale(0.9); }
  75% { transform: translate(30px, 10px) scale(1.05); }
}

.animate-blob {
  animation: blob 7s infinite;
}

.animation-delay-2000 {
  animation-delay: 2s;
}

.animation-delay-4000 {
  animation-delay: 4s;
}
```
