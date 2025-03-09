const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

let config;

try {
    const configPath = path.join(__dirname, '../../config/config.yml');
    const fileContents = fs.readFileSync(configPath, 'utf8');
    const allConfig = yaml.load(fileContents);
    
    const environment = process.env.NODE_ENV || 'development';
    config = allConfig[environment];
} catch (e) {
    console.error('Error loading config:', e);
    process.exit(1);
}

module.exports = config;
