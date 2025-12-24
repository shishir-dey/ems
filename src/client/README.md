# Enterprise Management Suite (EMS) Client

## Tech Stack

### Core Technologies
- **React 19.1.0** - Modern UI library with latest features
- **TypeScript 5.8.3** - Type-safe JavaScript development
- **Vite 6.3.5** - Fast build tool and development server

### Styling & UI
- **Tailwind CSS 4.1.8** - Utility-first CSS framework
- **Radix UI** - Accessible, unstyled UI primitives
  - Alert Dialog, Label, Select, Slot, Switch components
- **Lucide React** - Beautiful & consistent icon library
- **class-variance-authority** - Type-safe component variants
- **tailwind-merge** - Utility for merging Tailwind classes

### Routing & HTTP
- **React Router DOM 7.6.2** - Declarative routing for React
- **Axios 1.9.0** - Promise-based HTTP client

### Development Tools
- **ESLint** - Code linting and quality checks
- **Prettier** - Code formatting
- **TypeScript ESLint** - TypeScript-specific linting rules

## Project Structure

```
src/
├── components/           # React components
│   ├── ui/              # Reusable UI components (buttons, inputs, etc.)
│   ├── persons/         # Person management components
│   ├── jobs/            # Job management components
│   ├── orders/          # Order management components
│   └── sidebar.tsx      # Main navigation sidebar
├── services/            # API service layer
│   ├── personService.ts # Person-related API calls
│   ├── jobService.ts    # Job-related API calls
│   └── orderService.ts  # Order-related API calls
├── types/               # TypeScript type definitions
│   ├── person.ts        # Person entity types
│   ├── job.ts           # Job entity types
│   └── order.ts         # Order entity types
├── misc/                # Utility functions and helpers
│   └── utils.ts         # Common utility functions
├── App.tsx              # Main application component
├── main.tsx             # Application entry point
└── index.css            # Global styles and CSS variables
```

## Development Setup

### Prerequisites
- Node.js (version 18 or higher recommended)
- npm or yarn package manager

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd ems-client-react
```

2. Install dependencies
```bash
npm install
```

3. Configure environment
   - The project loads configuration from `../../config.env`
   - Default ports: Frontend (3001), Backend (5002)

4. Start development server
```bash
npm start
```

### Available Scripts

- `npm start` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint code analysis
- `npm run format` - Format code with Prettier
