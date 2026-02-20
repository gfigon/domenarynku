// Konfiguracja Klaro Cookie Consent dla domenarynku.pl
var klaroConfig = {
    // Wersja językowa
    lang: 'pl',
    
    // Czy zastosować Consent Mode v2 (Google)
    mustConsent: true,
    
    // Czy zgody są opcjonalne (false = użytkownik musi wybrać)
    acceptAll: true,
    
    // Czy pokazać toggle dla wszystkich kategorii naraz
    hideDeclineAll: false,
    
    // Czy pokazać link do polityki prywatności
    privacyPolicy: '/polityka-prywatnosci',
    
    // Ustawienia wyglądu - USUNIĘTE theme, będziemy sterować przez CSS
    styling: {
        theme: ['bottom', 'wide'],
    },
    
    // Tłumaczenia polskie
    translations: {
        pl: {
            consentModal: {
                title: 'Szanujemy Twoją prywatność',
                description: 'Używamy plików cookies i podobnych technologii do personalizacji treści, analizy ruchu i reklam. Możesz zarządzać swoimi preferencjami poniżej.',
            },
            consentNotice: {
                description: 'Używamy plików cookies do analizy ruchu, personalizacji treści i wyświetlania reklam. Możesz zarządzać swoimi preferencjami dotyczącymi cookies.',
                learnMore: 'Dostosuj ustawienia',
            },
            purposes: {
                analytics: {
                    title: 'Analytics i statystyki',
                    description: 'Pozwalają nam zrozumieć jak używasz naszej strony i poprawić jej jakość.',
                },
                marketing: {
                    title: 'Marketing i reklamy',
                    description: 'Pomagają nam wyświetlać spersonalizowane reklamy i mierzyć ich skuteczność.',
                },
                personalization: {
                    title: 'Personalizacja',
                    description: 'Pozwalają zapamiętać Twoje preferencje i dostosować treści do Twoich zainteresowań.',
                },
                social: {
                    title: 'Media społecznościowe',
                    description: 'Umożliwiają dzielenie się treściami w mediach społecznościowych.',
                },
            },
            ok: 'Akceptuję wybrane',
            acceptAll: 'Akceptuję wszystkie',
            acceptSelected: 'Akceptuję wybrane',
            decline: 'Odrzuć wszystkie',
            save: 'Zapisz ustawienia',
            close: 'Zamknij',
        },
    },
    
    // Definicje poszczególnych serwisów/cookies
    services: [
        {
            name: 'google-analytics',
            title: 'Google Analytics',
            purposes: ['analytics'],
            required: false,
            optOut: false,
            default: false,
            onlyOnce: false,
            cookies: [
                [/^_ga/, '/', 'domenarynku.pl'],
                [/^_gid/, '/', 'domenarynku.pl'],
            ],
            callback: function(consent, service) {
                // Consent Mode v2 dla Google Analytics
                if (consent) {
                    window.dataLayer = window.dataLayer || [];
                    function gtag(){dataLayer.push(arguments);}
                    gtag('consent', 'update', {
                        'analytics_storage': 'granted'
                    });
                } else {
                    window.dataLayer = window.dataLayer || [];
                    function gtag(){dataLayer.push(arguments);}
                    gtag('consent', 'update', {
                        'analytics_storage': 'denied'
                    });
                }
            },
        },
        {
            name: 'google-ads',
            title: 'Google Ads',
            purposes: ['marketing'],
            required: false,
            optOut: false,
            default: false,
            onlyOnce: false,
            cookies: [
                [/^_gcl_/, '/', 'domenarynku.pl'],
            ],
            callback: function(consent, service) {
                // Consent Mode v2 dla Google Ads
                if (consent) {
                    window.dataLayer = window.dataLayer || [];
                    function gtag(){dataLayer.push(arguments);}
                    gtag('consent', 'update', {
                        'ad_storage': 'granted',
                        'ad_user_data': 'granted',
                        'ad_personalization': 'granted'
                    });
                } else {
                    window.dataLayer = window.dataLayer || [];
                    function gtag(){dataLayer.push(arguments);}
                    gtag('consent', 'update', {
                        'ad_storage': 'denied',
                        'ad_user_data': 'denied',
                        'ad_personalization': 'denied'
                    });
                }
            },
        },
        {
            name: 'preferences',
            title: 'Preferencje użytkownika',
            purposes: ['personalization'],
            required: false,
            default: false,
            cookies: [
                ['user_preferences', '/', 'domenarynku.pl'],
            ],
        },
    ],
    
    // Domyślne zgody (przed wyborem użytkownika)
    default: {
        analytics: false,
        marketing: false,
        personalization: false,
        social: false,
    },
};

