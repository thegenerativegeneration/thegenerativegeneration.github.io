// get the ninja-keys element
const ninja = document.querySelector('ninja-keys');

// add the home and posts menu items
ninja.data = [{
    id: "nav-about",
    title: "about",
    section: "Navigation",
    handler: () => {
      window.location.href = "/";
    },
  },{id: "nav-works",
          title: "works",
          description: "A collection of my creative works.",
          section: "Navigation",
          handler: () => {
            window.location.href = "/works/";
          },
        },{id: "nav-publications",
          title: "publications",
          description: "Published research papers, articles, and other works.",
          section: "Navigation",
          handler: () => {
            window.location.href = "/publications/";
          },
        },{id: "nav-experiments",
          title: "experiments",
          description: "Creative experiments, and projects to be.",
          section: "Navigation",
          handler: () => {
            window.location.href = "/experiments/";
          },
        },{id: "nav-blog",
          title: "blog",
          description: "",
          section: "Navigation",
          handler: () => {
            window.location.href = "/blog/";
          },
        },{id: "post-coming-soon",
        
          title: 'Coming soon <svg width="1.2rem" height="1.2rem" top=".5rem" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg"><path d="M17 13.5v6H5v-12h6m3-3h6v6m0-6-9 9" class="icon_svg-stroke" stroke="#999" stroke-width="1.5" fill="none" fill-rule="evenodd" stroke-linecap="round" stroke-linejoin="round"></path></svg>',
        
        description: "This is Philipp&amp;#8217;s Substack.",
        section: "Posts",
        handler: () => {
          
            window.open("https://philipphaslbauer.substack.com/p/coming-soon", "_blank");
          
        },
      },{id: "post-easiest-way-to-use-3d-gaussians-splatting",
        
          title: "Easiest Way To Use 3D Gaussians Splatting",
        
        description: "How can I teach people who have never worked with 3D graphics to use 3D Gaussian Splatting?",
        section: "Posts",
        handler: () => {
          
            window.location.href = "/blog/2024/easy-3dgs/";
          
        },
      },{id: "post-control-how-to-steer-diffusion-models",
        
          title: "Control - How to Steer Diffusion Models",
        
        description: "How can I steer generative models like Stable Diffusion?",
        section: "Posts",
        handler: () => {
          
            window.location.href = "/blog/2023/controlling-diffusion/";
          
        },
      },{id: "books-the-godfather",
          title: 'The Godfather',
          description: "",
          section: "Books",handler: () => {
              window.location.href = "/books/the_godfather/";
            },},{id: "experiments-voice-animation-2023",
          title: 'Voice Animation (2023)',
          description: "A simple audio visualization.",
          section: "Experiments",handler: () => {
              window.location.href = "/experiments/one/";
            },},{id: "experiments-voice-puppetry-2023",
          title: 'Voice Puppetry (2023)',
          description: "A mannequin audio visualization.",
          section: "Experiments",handler: () => {
              window.location.href = "/experiments/two/";
            },},{id: "news-a-simple-inline-announcement",
          title: 'A simple inline announcement.',
          description: "",
          section: "News",},{id: "news-a-long-announcement-with-details",
          title: 'A long announcement with details',
          description: "",
          section: "News",handler: () => {
              window.location.href = "/news/announcement_2/";
            },},{id: "news-a-simple-inline-announcement-with-markdown-emoji-sparkles-smile",
          title: 'A simple inline announcement with Markdown emoji! :sparkles: :smile:',
          description: "",
          section: "News",},{id: "projects-deus-in-machina-2024",
          title: 'Deus in Machina (2024)',
          description: "A church installation with an AI avatar of Jesus Christ.",
          section: "Projects",handler: () => {
              window.location.href = "/projects/deus-in-machina/";
            },},{
        id: 'social-email',
        title: 'email',
        section: 'Socials',
        handler: () => {
          window.open("mailto:%70%68%68%61%73%6C%62%61%75%65%72@%79%61%68%6F%6F.%64%65", "_blank");
        },
      },{
        id: 'social-instagram',
        title: 'Instagram',
        section: 'Socials',
        handler: () => {
          window.open("https://instagram.com/feili667", "_blank");
        },
      },{
        id: 'social-linkedin',
        title: 'LinkedIn',
        section: 'Socials',
        handler: () => {
          window.open("https://www.linkedin.com/in/haslbauer your LinkedIn user name", "_blank");
        },
      },{
        id: 'social-scholar',
        title: 'Google Scholar',
        section: 'Socials',
        handler: () => {
          window.open("https://scholar.google.com/citations?user=D1wjUg0AAAAJ", "_blank");
        },
      },];
