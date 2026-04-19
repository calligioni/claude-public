# Dashboard Layout & Components Templates

Ready-to-use dashboard components in React + Tailwind CSS.

---

## Dashboard Layout Shell

```jsx
function DashboardLayout({ children }) {
  return (
    <div className="min-h-screen bg-slate-50">
      {/* Sidebar */}
      <aside className="fixed inset-y-0 left-0 w-64 bg-slate-900 text-white">
        {/* Logo */}
        <div className="h-16 flex items-center px-6 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-500 rounded-lg"></div>
            <span className="font-semibold text-lg">Dashboard</span>
          </div>
        </div>
        
        {/* Navigation */}
        <nav className="p-4 space-y-1">
          <NavItem icon="home" label="Overview" active />
          <NavItem icon="chart" label="Analytics" />
          <NavItem icon="users" label="Customers" />
          <NavItem icon="folder" label="Projects" />
          <NavItem icon="settings" label="Settings" />
        </nav>
        
        {/* User section */}
        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-slate-700"></div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">John Doe</p>
              <p className="text-xs text-slate-400 truncate">john@company.com</p>
            </div>
          </div>
        </div>
      </aside>
      
      {/* Main content */}
      <div className="ml-64">
        {/* Top header */}
        <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-8">
          <div className="flex items-center gap-4">
            <h1 className="text-xl font-semibold text-slate-900">Dashboard</h1>
          </div>
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
              <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </button>
            <button className="p-2 hover:bg-slate-100 rounded-lg transition-colors relative">
              <svg className="w-5 h-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-5 5v-5zM4.828 4.828a4 4 0 015.656 0l.516.516.516-.516a4 4 0 015.656 5.656L11 16l-6.172-6.172a4 4 0 010-5.656z" />
              </svg>
              <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
            </button>
          </div>
        </header>
        
        {/* Page content */}
        <main className="p-8">
          {children}
        </main>
      </div>
    </div>
  );
}

function NavItem({ icon, label, active }) {
  return (
    <a
      href="#"
      className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
        active 
          ? 'bg-blue-600 text-white' 
          : 'text-slate-400 hover:text-white hover:bg-slate-800'
      }`}
    >
      <span className="w-5 h-5">{/* Icon */}</span>
      <span className="font-medium">{label}</span>
    </a>
  );
}
```

---

## Stats Cards

### Simple Stat Card

```jsx
function StatCard({ title, value, change, changeType, icon }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-slate-500">{title}</p>
          <p className="text-3xl font-bold text-slate-900">{value}</p>
          <div className="flex items-center gap-2">
            <span className={`inline-flex items-center text-sm font-medium ${
              changeType === 'positive' ? 'text-emerald-600' : 'text-red-600'
            }`}>
              {changeType === 'positive' ? (
                <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
                </svg>
              ) : (
                <svg className="w-4 h-4 mr-1" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              )}
              {change}
            </span>
            <span className="text-sm text-slate-500">vs last month</span>
          </div>
        </div>
        <div className="p-3 bg-blue-50 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );
}

// Usage
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard 
    title="Total Revenue" 
    value="$45,231.89" 
    change="+20.1%" 
    changeType="positive"
    icon={<DollarIcon className="w-6 h-6 text-blue-600" />}
  />
  <StatCard 
    title="Subscriptions" 
    value="+2,350" 
    change="+180.1%" 
    changeType="positive"
    icon={<UsersIcon className="w-6 h-6 text-blue-600" />}
  />
  <StatCard 
    title="Active Now" 
    value="+573" 
    change="+201" 
    changeType="positive"
    icon={<ActivityIcon className="w-6 h-6 text-blue-600" />}
  />
  <StatCard 
    title="Bounce Rate" 
    value="24.5%" 
    change="-4.3%" 
    changeType="positive"
    icon={<TrendingDownIcon className="w-6 h-6 text-blue-600" />}
  />
</div>
```

### Mini Stat Card (Dark)

```jsx
function MiniStatCard({ title, value, icon, color }) {
  const colorClasses = {
    blue: 'from-blue-500 to-blue-600',
    purple: 'from-purple-500 to-purple-600',
    emerald: 'from-emerald-500 to-emerald-600',
    amber: 'from-amber-500 to-amber-600',
  };
  
  return (
    <div className={`bg-gradient-to-br ${colorClasses[color]} rounded-xl p-6 text-white`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-white/80">{title}</p>
          <p className="text-3xl font-bold mt-1">{value}</p>
        </div>
        <div className="p-3 bg-white/20 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );
}
```

---

## Chart Card

```jsx
function ChartCard({ title, subtitle, children }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
          {subtitle && <p className="text-sm text-slate-500">{subtitle}</p>}
        </div>
        <div className="flex items-center gap-2">
          <button className="px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
            7D
          </button>
          <button className="px-3 py-1.5 text-sm font-medium bg-slate-900 text-white rounded-lg">
            30D
          </button>
          <button className="px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
            90D
          </button>
        </div>
      </div>
      {children}
    </div>
  );
}

// With Recharts
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

function RevenueChart({ data }) {
  return (
    <ChartCard title="Revenue Overview" subtitle="Monthly recurring revenue">
      <div className="h-80">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis dataKey="month" stroke="#64748b" fontSize={12} />
            <YAxis stroke="#64748b" fontSize={12} />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: '#fff', 
                border: '1px solid #e2e8f0',
                borderRadius: '8px',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
              }} 
            />
            <Line 
              type="monotone" 
              dataKey="revenue" 
              stroke="#3b82f6" 
              strokeWidth={2}
              dot={{ fill: '#3b82f6', strokeWidth: 2 }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </ChartCard>
  );
}
```

---

## Data Table

```jsx
function DataTable({ columns, data }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-slate-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-slate-900">Recent Transactions</h3>
          <button className="text-sm font-medium text-blue-600 hover:text-blue-700">
            View all
          </button>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="bg-slate-50">
              {columns.map((col) => (
                <th 
                  key={col.key}
                  className="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider"
                >
                  {col.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {data.map((row, idx) => (
              <tr key={idx} className="hover:bg-slate-50 transition-colors">
                {columns.map((col) => (
                  <td key={col.key} className="px-6 py-4 whitespace-nowrap">
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// Column definitions with custom renders
const columns = [
  { 
    key: 'customer', 
    label: 'Customer',
    render: (value, row) => (
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-blue-600"></div>
        <div>
          <p className="font-medium text-slate-900">{value}</p>
          <p className="text-sm text-slate-500">{row.email}</p>
        </div>
      </div>
    )
  },
  { key: 'amount', label: 'Amount' },
  { 
    key: 'status', 
    label: 'Status',
    render: (value) => (
      <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${
        value === 'Completed' 
          ? 'bg-emerald-100 text-emerald-700' 
          : value === 'Pending'
          ? 'bg-amber-100 text-amber-700'
          : 'bg-red-100 text-red-700'
      }`}>
        {value}
      </span>
    )
  },
  { key: 'date', label: 'Date' },
];
```

---

## Activity Feed

```jsx
function ActivityFeed({ activities }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6">
      <h3 className="text-lg font-semibold text-slate-900 mb-6">Recent Activity</h3>
      <div className="space-y-6">
        {activities.map((activity, idx) => (
          <div key={idx} className="flex gap-4">
            <div className="relative">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                activity.type === 'success' ? 'bg-emerald-100' :
                activity.type === 'warning' ? 'bg-amber-100' :
                'bg-blue-100'
              }`}>
                {activity.icon}
              </div>
              {idx < activities.length - 1 && (
                <div className="absolute top-10 left-1/2 -translate-x-1/2 w-px h-6 bg-slate-200"></div>
              )}
            </div>
            <div className="flex-1 pt-1">
              <p className="text-sm text-slate-900">
                <span className="font-medium">{activity.user}</span>
                {' '}{activity.action}
              </p>
              <p className="text-xs text-slate-500 mt-1">{activity.time}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## Progress Card

```jsx
function ProgressCard({ title, current, total, percentage }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-medium text-slate-900">{title}</h3>
        <span className="text-sm text-slate-500">{current} / {total}</span>
      </div>
      <div className="w-full bg-slate-100 rounded-full h-2">
        <div 
          className="bg-blue-600 h-2 rounded-full transition-all duration-500"
          style={{ width: `${percentage}%` }}
        ></div>
      </div>
      <p className="text-sm text-slate-500 mt-2">{percentage}% complete</p>
    </div>
  );
}
```

---

## Empty State

```jsx
function EmptyState({ icon, title, description, action }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-12 text-center">
      <div className="w-16 h-16 mx-auto mb-6 bg-slate-100 rounded-full flex items-center justify-center text-slate-400">
        {icon}
      </div>
      <h3 className="text-lg font-semibold text-slate-900 mb-2">{title}</h3>
      <p className="text-slate-500 max-w-sm mx-auto mb-6">{description}</p>
      {action && (
        <button className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors">
          {action}
        </button>
      )}
    </div>
  );
}

// Usage
<EmptyState 
  icon={<FolderIcon className="w-8 h-8" />}
  title="No projects yet"
  description="Get started by creating your first project. It only takes a few seconds."
  action="Create Project"
/>
```
