const path = require('path');

const COLORS = {
  reset: '\x1b[0m',
  info: '\x1b[34m',
  warn: '\x1b[33m',
  error: '\x1b[31m',
  debug: '\x1b[35m',
  log: '\x1b[37m',
};

const parseStackTrace = (stack) => {
  const lines = stack.split('\n');
  
  for (let i = 2; i < Math.min(lines.length, 6); i++) {
    const line = lines[i];
    
    if (line.includes(__filename) || 
        line.includes('node_modules') || 
        line.includes('internal/') ||
        line.includes('Module.')) {
      continue;
    }
    
    const patterns = [
      /\((.*):(\d+):(\d+)\)$/,
      /at .* \((.*):(\d+):(\d+)\)$/,    
      /at (.*):(\d+):(\d+)$/,      
      /^\s*at (.*):(\d+):(\d+)$/,  
    ];
    
    for (const pattern of patterns) {
      const match = line.match(pattern);
      if (match) {
        const [_, file, lineNum] = match;
        
        if (file && !file.includes('<anonymous>') && !file.includes('eval')) {
          return `${path.basename(file)}:${lineNum}`;
        }
      }
    }
  }
  
  return 'unknown';
};

const log = async (message, type = 'info') => {
  const stack = new Error().stack;
  const location = parseStackTrace(stack);
  
  const color = COLORS[type] || COLORS.log;
  const reset = COLORS.reset;

  console.log(`${color}[${type}] ${location}${reset}`, message);
};


module.exports = { log };