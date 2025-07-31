# 🎬 Hawke Minimal Theme for UNIT3D 9.1.5

A clean, minimalist theme inspired by the elegant design of Hawke-uno tracker. This theme brings a modern cyan/teal aesthetic with enhanced navigation and statistical dashboard.

## 🌟 Features

- **Clean Design**: Minimalist interface with generous spacing
- **Cyan/Teal Theme**: Inspired by Hawke-uno's color scheme
- **Stats Dashboard**: Statistics header showing online users, featured torrents, news, topics, and server time
- **Enhanced Navigation**: User statistics in top navigation bar
- **Glass Morphism**: Modern backdrop blur effects throughout the interface
- **Responsive Design**: Works perfectly on desktop, tablet, and mobile
- **Modern CSS**: Uses CSS custom properties for easy customization

## 📸 Screenshots

You can preview the theme by opening `hawke-theme-preview.html` in your browser.

## 🚀 Installation

### Automatic Installation (Recommended)

**For Windows:**
```cmd
install-hawke-theme.bat
```

**For Linux/Mac:**
```bash
chmod +x install-hawke-theme.sh
./install-hawke-theme.sh
```

### Manual Installation

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Build Assets:**
   ```bash
   npm run build
   ```

3. **Clear Caches:**
   ```bash
   php artisan cache:clear
   php artisan view:clear
   php artisan config:clear
   ```

4. **Start Server:**
   ```bash
   php artisan serve
   ```

## 📁 Files Created/Modified

### New Theme Files:
- `resources/sass/themes/_hawke-minimal.scss` - Main theme variables and global styles
- `resources/sass/components/_hawke-navigation.scss` - Enhanced navigation styling
- `resources/views/home/hawke-index.blade.php` - Alternative home page template
- `hawke-theme-preview.html` - Static preview of the theme

### Modified Files:
- `resources/sass/main.scss` - Added theme imports
- `resources/views/home/index.blade.php` - Updated with Hawke styling
- `resources/views/home/index-original.blade.php` - Backup of original

## 🎨 Customization

### Color Scheme

Edit `resources/sass/themes/_hawke-minimal.scss` to customize colors:

```scss
:root {
    --color-primary: #00bcd4;           /* Main cyan */
    --color-primary-dark: #0097a7;     /* Darker cyan */
    --color-primary-light: #40e0f0;    /* Light cyan */
    
    /* Customize these for your tracker */
    --color-accent: #ff6b35;           /* Orange for highlights */
    --color-success: #4caf50;          /* Green */
    --color-warning: #ff9800;          /* Orange */
    --color-error: #f44336;            /* Red */
}
```

### Background

Change the main background gradient:

```scss
--gradient-primary: linear-gradient(135deg, #0d1b1f 0%, #1a2b32 50%, #263238 100%);
```

### Statistics

Modify the statistics shown in the header by editing:
`resources/views/home/index.blade.php`

## 🔧 Troubleshooting

### Assets Not Loading
- Run `npm run build` to compile assets
- Clear browser cache
- Check file permissions

### PHP Errors
- Ensure you're using the correct model methods
- Clear Laravel caches with `php artisan cache:clear`

### Styling Issues
- Check that CSS custom properties are supported in your browser
- Ensure the theme SCSS files are properly imported

## 🌐 Browser Support

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## 📋 Requirements

- UNIT3D 9.1.5
- Node.js 16+
- npm 8+
- PHP 8.1+
- Laravel 10+

## 🤝 Contributing

Feel free to customize this theme for your tracker. You can:

1. Modify color schemes
2. Add new components
3. Enhance responsive design
4. Add animations

## 📄 License

This theme follows the same license as UNIT3D Community Edition.

## 🙏 Credits

- Inspired by Hawke-uno tracker design
- Built for UNIT3D Community Edition
- Uses Font Awesome icons

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section
2. Verify all files were created correctly
3. Ensure assets are compiled
4. Clear all caches

---

**Enjoy your new Hawke Minimal theme! 🌊**
