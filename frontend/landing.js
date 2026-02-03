/**
 * Smart Elevator Landing Page - JavaScript
 * Animations and interactions
 */

// Animated word rotation for hero section
const words = ['SCAN Algorithm', 'Smart Scheduling', 'Efficient Design', '40% Faster'];
let currentWordIndex = 0;

function animateWord() {
    const wordElement = document.getElementById('animatedWord');
    if (!wordElement) return;

    // Fade out
    wordElement.style.opacity = '0';
    wordElement.style.transform = 'translateY(-20px)';

    setTimeout(() => {
        currentWordIndex = (currentWordIndex + 1) % words.length;
        wordElement.textContent = words[currentWordIndex];

        // Fade in
        wordElement.style.opacity = '1';
        wordElement.style.transform = 'translateY(0)';
    }, 300);
}

// Start word animation
setInterval(animateWord, 3000);

// Tubelight Navbar - Active State Management
const navItems = document.querySelectorAll('.nav-item[data-section]');
const sections = document.querySelectorAll('section[id], .hero');

function updateActiveNavItem() {
    const scrollPosition = window.scrollY + 200;

    // Check which section is currently in view
    let currentSection = 'hero';

    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.offsetHeight;

        if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
            currentSection = section.id || 'hero';
        }
    });

    // Update active class on nav items
    navItems.forEach(item => {
        const itemSection = item.dataset.section;
        if (itemSection === currentSection) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const targetId = this.getAttribute('href');
        const target = targetId === '#' ? document.querySelector('.hero') : document.querySelector(targetId);

        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });

            // Update active state immediately on click
            navItems.forEach(item => item.classList.remove('active'));
            if (this.dataset.section) {
                this.classList.add('active');
            }
        }
    });
});

// Update active nav item on scroll
window.addEventListener('scroll', updateActiveNavItem);
window.addEventListener('load', updateActiveNavItem);

// Intersection Observer for scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
        }
    });
}, observerOptions);

// Observe elements for scroll animations
document.querySelectorAll('.feature-card, .algo-card, .step-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// Add animation class styles
const style = document.createElement('style');
style.textContent = `
    .animate-in {
        opacity: 1 !important;
        transform: translateY(0) !important;
    }
`;
document.head.appendChild(style);

// Add transition to animated word
document.addEventListener('DOMContentLoaded', () => {
    const wordElement = document.getElementById('animatedWord');
    if (wordElement) {
        wordElement.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
    }
});

console.log('🏢 Smart Elevator Landing Page Loaded');
