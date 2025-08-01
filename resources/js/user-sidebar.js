/**
 * User Sidebar Component
 * Handles the left sidebar menu functionality with responsive behavior
 */
class UserSidebar {
    constructor() {
        this.sidebar = document.querySelector('.user-sidebar');
        this.overlay = document.querySelector('.user-sidebar__overlay');
        this.toggleBtn = document.querySelector('.user-sidebar__toggle');
        this.closeBtn = document.querySelector('.user-sidebar__close');
        this.body = document.body;
        
        this.isOpen = false;
        this.isMobile = window.innerWidth <= 768;
        
        this.init();
    }
    
    init() {
        if (!this.sidebar) return;
        
        this.bindEvents();
        this.updateResponsive();
        this.setActiveLink();
        this.adjustTogglePosition();
    }
    
    adjustTogglePosition() {
        // Adjust toggle button position based on header height
        const header = document.querySelector('header');
        const secondaryNav = document.querySelector('.secondary-nav');
        
        if (header && this.toggleBtn) {
            let headerHeight = header.offsetHeight;
            
            // Add extra spacing if there's secondary navigation
            if (secondaryNav) {
                headerHeight += 20; // Extra padding
            }
            
            // Set minimum top position
            const minTop = 120;
            const calculatedTop = Math.max(minTop, headerHeight + 10);
            
            this.toggleBtn.style.top = calculatedTop + 'px';
        }
    }
    
    bindEvents() {
        // Toggle button
        this.toggleBtn?.addEventListener('click', () => this.toggle());
        
        // Close button
        this.closeBtn?.addEventListener('click', () => this.close());
        
        // Overlay click
        this.overlay?.addEventListener('click', () => this.close());
        
        // Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.close();
            }
        });
        
        // Window resize
        window.addEventListener('resize', () => this.handleResize());
        
        // Menu links
        this.sidebar?.querySelectorAll('.user-sidebar__menu-link').forEach(link => {
            link.addEventListener('click', (e) => {
                // Close sidebar on mobile after clicking a link
                if (this.isMobile) {
                    setTimeout(() => this.close(), 100);
                }
            });
        });
        
        // Prevent body scroll when sidebar is open on mobile
        this.sidebar?.addEventListener('touchmove', (e) => {
            if (this.isOpen && this.isMobile) {
                e.stopPropagation();
            }
        });
    }
    
    toggle() {
        if (this.isOpen) {
            this.close();
        } else {
            this.open();
        }
    }
    
    open() {
        if (!this.sidebar) return;
        
        this.isOpen = true;
        this.sidebar.classList.add('open');
        this.overlay?.classList.add('active');
        
        // Prevent body scroll on mobile
        if (this.isMobile) {
            this.body.style.overflow = 'hidden';
        }
        
        // Focus first menu item for accessibility
        const firstLink = this.sidebar.querySelector('.user-sidebar__menu-link');
        if (firstLink) {
            setTimeout(() => firstLink.focus(), 300);
        }
        
        // Update toggle button aria
        if (this.toggleBtn) {
            this.toggleBtn.setAttribute('aria-expanded', 'true');
            this.toggleBtn.setAttribute('aria-label', 'Cerrar menú de usuario');
        }
        
        // Trigger custom event
        document.dispatchEvent(new CustomEvent('userSidebarOpen'));
    }
    
    close() {
        if (!this.sidebar) return;
        
        this.isOpen = false;
        this.sidebar.classList.remove('open');
        this.overlay?.classList.remove('active');
        
        // Restore body scroll
        this.body.style.overflow = '';
        
        // Update toggle button aria
        if (this.toggleBtn) {
            this.toggleBtn.setAttribute('aria-expanded', 'false');
            this.toggleBtn.setAttribute('aria-label', 'Abrir menú de usuario');
        }
        
        // Trigger custom event
        document.dispatchEvent(new CustomEvent('userSidebarClose'));
    }
    
    handleResize() {
        const wasMobile = this.isMobile;
        this.isMobile = window.innerWidth <= 768;
        
        // If switching from mobile to desktop while open
        if (wasMobile && !this.isMobile && this.isOpen) {
            this.body.style.overflow = '';
        }
        
        // If switching from desktop to mobile while open
        if (!wasMobile && this.isMobile && this.isOpen) {
            this.body.style.overflow = 'hidden';
        }
        
        this.updateResponsive();
        this.adjustTogglePosition(); // Reajust position on resize
    }
    
    updateResponsive() {
        // Close sidebar when switching to desktop if it was open on mobile
        if (!this.isMobile && this.isOpen) {
            // On desktop, we might want to keep it open or close it based on preference
            // For now, we'll close it to maintain consistency
            setTimeout(() => this.close(), 100);
        }
    }
    
    setActiveLink() {
        const currentPath = window.location.pathname;
        const menuLinks = this.sidebar?.querySelectorAll('.user-sidebar__menu-link');
        
        menuLinks?.forEach(link => {
            const href = link.getAttribute('href');
            link.classList.remove('active');
            
            if (href && (currentPath === href || currentPath.startsWith(href + '/'))) {
                link.classList.add('active');
            }
        });
    }
    
    // Public methods for external control
    static getInstance() {
        if (!window.userSidebarInstance) {
            window.userSidebarInstance = new UserSidebar();
        }
        return window.userSidebarInstance;
    }
    
    static open() {
        UserSidebar.getInstance().open();
    }
    
    static close() {
        UserSidebar.getInstance().close();
    }
    
    static toggle() {
        UserSidebar.getInstance().toggle();
    }
}

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    UserSidebar.getInstance();
    
    // Also adjust position after a short delay to ensure all content is loaded
    setTimeout(() => {
        const instance = UserSidebar.getInstance();
        if (instance.adjustTogglePosition) {
            instance.adjustTogglePosition();
        }
    }, 500);
});

// Alpine.js integration (if available)
if (window.Alpine) {
    document.addEventListener('alpine:init', () => {
        Alpine.data('userSidebar', () => ({
            isOpen: false,
            
            toggle() {
                this.isOpen = !this.isOpen;
                if (this.isOpen) {
                    UserSidebar.open();
                } else {
                    UserSidebar.close();
                }
            },
            
            close() {
                this.isOpen = false;
                UserSidebar.close();
            },
            
            init() {
                // Listen for sidebar events
                document.addEventListener('userSidebarOpen', () => {
                    this.isOpen = true;
                });
                
                document.addEventListener('userSidebarClose', () => {
                    this.isOpen = false;
                });
            }
        }));
    });
}

// Global functions for inline onclick handlers
window.toggleUserSidebar = function() {
    UserSidebar.toggle();
};

window.closeUserSidebar = function() {
    UserSidebar.close();
};

window.openUserSidebar = function() {
    UserSidebar.open();
};

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = UserSidebar;
}

// Global access
window.UserSidebar = UserSidebar;
